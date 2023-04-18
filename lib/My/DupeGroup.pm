package My::DupeGroup;
use warnings;
use strict;
no strict 'refs';      ## no critic (ProhibitNoStrict) [for FileCache]

=head1 NAME

My::DupeGroup - Find duplicates among a number of files.

=head1 DESCRIPTION

This package exports a subroutine called C<group_dupes> that reads a
number of specified files, and finds and returns groups of files with
the same content among them.

Let's say files A, B, and C have the exact same contents; files D and
E have the exact same contents up to a specific offset; file F has the
exact same contents as files A through C up to a later offset; and
file G is the only file that has its contents.

Before reading, all files are assumed to have the same content:

    [A, B, C, D, E, F, G]

Next we read a chunk of data from each file.  Since G is the only file
that contains its first chunk, its filehandle is closed and it will
not be returned as part of any group.  All of the other files have the
same contents up to a certain offset and are part of the same group:

    [A, B, C, D, E, F]

Let's read additional chunks from the six remaining files.  The chunks
of data are all going to be the same until they're not.  Let's say
files D and E yield identical chunks of data, and files A through C
and F yield another, different, identical chunk of data.  At this point,
files D and E split off into a separate group.

    [A, B, C, F]   [D, E]

Let's say at a later point file F contains a different chunk of data
then A, B, and C (which all have the same contents).  F is split off
from the group and will not be returned as part of any group.

    [A, B, C]   [D, E]

During the remainder of execution, files A, B, and C will contain the
same data as one another; and files D and E will contain the same data
as one another.  After all files are closed, C<group_dupes> returns an
array of two array references like so:

    my @groups = group_dupes("A", "B", "C", "D", "E", "F");

    #   ==> (["A", "B", "C"], ["D", "E"])

If you happen to pass a set of filenames of varying sizes, no two
files of different file sizes (in bytes) will be a part of the same
group of files returned.  There is really no point in passing files
that are not the same size in bytes, but as part of its sanity checks,
this code checks for EOF, making it safe to do it.

=head1 BUGS

The C<group_dupes> subroutine assumes that the contents of the files
it is supplied with will not change during execution.  When this
happens, behavior is undefined.

=cut

use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(group_dupes);

use Fcntl qw(SEEK_SET);

our $BYTES = 4096;

use FindBin;
use lib "${FindBin::Bin}/../../lib";

use My::FileCache qw(cache_open cache_close cache_close_all);

sub group_dupes {
    my (@filenames) = @_;
    my $offset = 0;
    my @results;                 # collects groups of duplicate files
    my @groups = ([@filenames]); # initialize with one group
    while (1) {
        my @newgroups;
        foreach my $group (@groups) {
            my @done;           # all files in this group that are done
            my %group;          # group by next chunk of contents
            foreach my $filename (@$group) {
                my $fh = cache_open($filename);
                next if !defined $fh;
                my $data;
                my $bytes = sysread($fh, $data, $BYTES);
                if (!defined $bytes) { # error reading
                    cache_close($filename);
                } elsif (!$bytes) { # EOF, no more data
                    cache_close($filename);
                    push(@done, $filename);
                } else {        # we just read some data
                    push(@{$group{$data}}, $filename) if defined $data;
                }
            }
            if (scalar @done >= 2) {
                push(@results, [@done]);
            }
            foreach my $key (keys %group) {
                my $group = $group{$key};
                if (scalar @$group >= 2) {
                    push(@newgroups, $group);
                }
            }
        }
        if (!scalar @newgroups) {
            cache_close_all();
            return @results if wantarray;
            return [@results];
        }
        @groups = @newgroups;
        $offset += $BYTES;
    }
}

1;
