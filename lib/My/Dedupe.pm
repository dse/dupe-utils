package My::Dedupe;
use warnings;
use strict;

use constant ASCENDING => 1;
use constant DESCENDING => -1;

use FindBin;
use lib "${FindBin::Bin}/../../lib";
use My::Progress qw();

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless({}, $class);
    $self->{links_by_size_inode} = {};
    $self->{file_count} = 0;
    $self->{dry_run} = 0;
    $self->{force} = 0;
    $self->{verbose} = 0;
    $self->{order} = DESCENDING;
    %$self = (%$self, %args);
    return $self;
}

sub add_file {
    my ($self, $pathname, $dev, $ino, $size, $mtime) = @_;
    my $inode = "$dev,$ino";
    push(@{$self->{links_by_size_inode}->{$size}->{$inode}}, $pathname);

    $self->{progress} //= My::Progress->new(tick => 1);
    $self->{progress}->{file_count} //= 0;
    $self->{progress}->{file_count} += 1;
    $self->{progress}->printf("  %d files found", $self->{progress}->{file_count});
}

sub run {
    my ($self) = @_;

    $self->{progress}->clear();
    printf("  %d files found\n", $self->{file_count});

    my @size;
    my $order = $self->{order};
    if ($order == ASCENDING) {
        # remove small duplicates first
        @size = sort { $a <=> $b } keys %{$self->{links_by_size_inode}};
    } elsif ($order == DESCENDING) {
        # remove large duplicates first
        @size = sort { $b <=> $a } keys %{$self->{links_by_size_inode}};
    } else {
        die("UNEXPECTED: order must be ascending or descending");
    }
    foreach my $size (@size) {
        $self->check_files_of_size($size);
    }
}

sub check_files_of_size {
    my ($self, $size) = @_;
    $self->{progress}->printf("  chekcing %d-byte files ...", $size);
    my @inodes = keys %{$self->{links_by_size_inode}->{$size}};
    next if scalar @inodes < 2;
    my @filenames_to_read = sort map { $self->{links_by_size_inode}->{$size}->{$_}->[0] } @inodes;
    my %inodes_by_filename;
    my %links_by_inode;
    foreach my $inode (@inodes) {
        $links_by_inode{$inode} = $self->{links_by_size_inode}{$size}{$inode};
        foreach my $filename (@{$links_by_inode{$inode}}) {
            $inodes_by_filename{$filename} = $inode;
        }
    }
    my @duplicate_groups = group_dupes(@filenames_to_read); # the dirty work
    foreach my $duplicate_group (sort { $a->[0] cmp $b->[0] } @duplicate_groups) {
        my ($file_to_keep, @files_to_delete) = sort @$duplicate_group;
        if ($self->{dry_run}) {
            my $inode_to_keep = $inodes_by_filename{$file_to_keep};
            my @files_to_keep = @{$links_by_inode{$inode_to_keep}};
            foreach my $file_to_keep (@files_to_keep) {
                $self->{progress}->clear();
                printf("# keep %s # %s\n", $file_to_keep, $inode_to_keep);
                $self->{progress}->printf("  chekcing %d-byte files ...", $size);
            }
        }
        foreach my $file_to_delete (@files_to_delete) {
            my $inode_to_delete = $inodes_by_filename{$file_to_delete};
            my @links_to_delete = sort @{$links_by_inode{$inode_to_delete}};
            foreach my $link_to_delete (@links_to_delete) {
                if ($self->{force}) {
                    if (!unlink($link_to_delete)) {
                        $self->{progress}->clear();
                        warn("$link_to_delete: $!\n");
                        $self->{progress}->printf("  chekcing %d-byte files ...", $size);
                    } else {
                        if ($self->{verbose}) {
                            $self->{progress}->clear();
                            warn("rm $link_to_delete\n");
                            $self->{progress}->printf("  chekcing %d-byte files ...", $size);
                        }
                    }
                }
                if ($self->{dry_run}) {
                    $self->{progress}->clear();
                    printf("rm %s # %s\n", shell_quote($link_to_delete), $inode_to_delete);
                    $self->{progress}->printf("  chekcing %d-byte files ...", $size);
                }
            }
        }
    }
}

sub DESTROY {
    my $self = shift;
    $self->{progress}->clear() if defined $self->{progress};
}

1;
