package My::DupeGroup;
use warnings;
use strict;
no strict 'refs';      ## no critic (ProhibitNoStrict) [for FileCache]

use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(group_dupes);

use Fcntl qw(SEEK_SET);

our $MAXOPEN = 16;
our $BYTES = 4096;
our $touched_counter = 0;

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
                    cache_close($fh);
                } elsif (!$bytes) { # EOF, no more data
                    cache_close($fh);
                    push(@done, $filename);
                } else {        # we just read some data
                    push(@{$group{$data}}, $filename) if defined $data;
                }
            }
            if (scalar @done > 2) {
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
