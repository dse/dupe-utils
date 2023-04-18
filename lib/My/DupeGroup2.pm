package My::DupeGroup2;
use warnings;
use strict;
no strict 'refs';      ## no critic (ProhibitNoStrict) [for FileCache]

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
    while (scalar @groups) {
      group:
        foreach my $group (@groups) {
            # read data from all files in this group, splitting files
            # off when their contents differ (or they terminate or
            # error out earlier)
            while (scalar @$group >= 2) {
                # keep track of most recently used file, as that will
                # determine which group of files we keep reading.
                my $mru_filename;
                my $mru_data;

                # list of filenames keyed by their contents
                my %data;

                # keep track of which files we're reading
                my %alive = map { ($_ => 1) } @$group;

                # list of files we've finished reading this round;
                # they'll be part of a new group of files if there's
                # more than one
                my @done;

                foreach my $filename (@$group) {
                    # if only one file remains, it won't be part of
                    # any group, so we move on...
                    if (scalar keys %alive < 2) {
                        cache_close($filename) foreach keys %alive;
                        delete $alive{$_} foreach keys %alive;
                        next group;
                    }

                    # skip files we no longer need to read
                    next if !exists $alive{$filename};

                    # open file
                    my $fh = cache_open($filename);
                    if (!defined $fh) {
                        # file will not be part of group; keep reading
                        # other files
                        delete $alive{$filename};
                        continue;
                    }

                    # read data from file
                    my $data;
                    my $bytes = sysread($fh, $data, $BYTES);

                    # check results
                    if (!defined $bytes) {
                        # error encountered; file will not be part of
                        # group; keep reading other files
                        cache_close($filename);
                        delete $alive{$filename};
                        continue;
                    }
                    if (!$bytes) {
                        # done reading this file; keep reading other
                        # files
                        cache_close($filename);
                        delete $alive{$filename};
                        push(@done, $filename);
                        continue;
                    }

                    push(@{$data{$data}}, $filename) if defined $data;
                    $mru_filename = $filename;
                    $mru_data = $data;
                }

                # we have a group of filenames we're done reading, add
                # it to the results?
                if (scalar @done > 1) {
                    push(@results, [@done]);
                }

                # check if any files have different contents.
                # split off other groups of files.
                if (scalar keys %data > 1) {
                    my @data = keys %data;

                    # don't include this group of files, i.e., the
                    # group of files including most recently read
                    # file.
                    @data = grep { $_ ne $mru_data } @data;

                    foreach my $data (@data) {
                        my @filenames = @{$data{$data}};
                        if (scalar @filenames > 2) {
                            push(@groups, [@filenames]);
                        }
                    }
                }

                # which files are we still reading?
                @$group = grep { exists $alive{$_} } @$group;
            }

            # in case of one remaining file
            cache_close($_) foreach @$group;
        }                       # foreach my $group
    }                           # while scalar @groups

    return @results;
}

1;
