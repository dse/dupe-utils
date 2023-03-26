package My::DupeGroup;
use warnings;
use strict;
use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(group_dupes);
use Fcntl qw(SEEK_SET);
our $MAXOPEN = 16;
our $BYTES = 4096;
our $touched_counter = 0;
our %fh;
our %touched;
sub group_dupes {
    my (@filenames) = @_;
    my %done;
    my $offset = 0;
    my @results;                 # collects groups of duplicate filenames
    my @groups = ([@filenames]); # initialize with one group
    while (1) {
        my @newgroups;
        foreach my $group (@groups) {
            my @done;
            my %group;
            foreach my $filename (@$group) {
                my $data;
                my $fh = get_fh($filename, $offset);
                next if !defined $fh;
                my $bytes = sysread($fh, $data, $BYTES);
                $touched{$filename} = ++$touched_counter;
                if (!defined $bytes) {
                    close($fh);
                    delete $fh{$filename};
                } elsif (!$bytes) {
                    close($fh);
                    delete $fh{$filename};
                    push(@done, $filename);
                } else {
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
            return @results if wantarray;
            return [@results];
        }
        @groups = @newgroups;
        $offset += $BYTES;
    }
}
sub get_fh {
    my ($filename, $offset) = @_;
    my $fh = $fh{$filename};
    return $fh if defined $fh;
    if (scalar(keys(%fh)) >= $MAXOPEN) {
        my @touched_filenames = sort { $touched{$a} <=> $touched{$b} } keys %fh;
        my $count = scalar(keys(%fh)) - $MAXOPEN + 1;
        my @oldest_filenames = splice(@touched_filenames, 0, $count);
        foreach my $filename (@oldest_filenames) {
            close($fh{$filename}) if defined $fh{$filename};
            delete $fh{$filename};
        }
    }
    if (!open($fh, '<:raw', $filename)) {
        warn("$filename: $!\n");
        return;
    }
    if ($offset) {
        my $real_offset = sysseek($fh, $offset, SEEK_SET);
        if ($real_offset != $offset) {
            close($fh);
            delete $fh{$filename};
            return;
        }
    }
    $fh{$filename} = $fh;
    return $fh;
}
sub touch_fh {
    my ($filename) = @_;
    $touched{$filename} = ++$touched_counter;
}
1;
