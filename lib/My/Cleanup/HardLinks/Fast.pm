package My::Cleanup::HardLinks::Fast;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../../../../lib";
use My::Progress qw();

use File::Find qw(finddepth);

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub run {
    my $progress = My::Progress->new(tick => 1);
    my ($self, @dir) = @_;
    my $force = $self->{force};
    my $verbose = $self->{verbose};
    my $sort = $self->{sort};
    my $total_trees = scalar @dir;
    my $last;
    my $file_count = 0;
    my $dir_count = 0;
    my $rm_file_count = 0;
    my $rm_dir_count = 0;
    my $sub = sub {
        $progress->printf("  %d files found; %d removed; %d dirs found; %d removed",
                          $file_count, $rm_file_count, $dir_count, $rm_dir_count);
    };
    my $wanted = sub {
        my @lstat = lstat($_);
        return unless scalar @lstat;
        if (-d _) {
            $dir_count += 1;
            if ($force) {
                $rm_dir_count += 1;
                if (rmdir($_)) {
                    if ($verbose) {
                        $progress->clear();
                        warn("rmdir $File::Find::name\n") if $verbose;
                    }
                }
            }
            &$sub();
            return;
        }
        return if (!-f _);
        $file_count += 1;
        my $nlink = $lstat[3];
        if ($nlink < 2) {
            &$sub();
            return;
        }
        if ($force) {
            $rm_file_count += 1;
            if (unlink($_)) {
                if ($verbose) {
                    $progress->clear();
                    warn("rm $File::Find::name\n");
                }
            } else {
                $progress->clear();
                warn("$File::Find::name: $!\n");
            }
        } else {
            $rm_file_count += 1;
            if ($verbose) {
                $progress->clear();
                warn("rm $File::Find::name\n");
            }
        }
        &$sub();
    };

    my $preprocess = sub {
        return sort @_;         ## no critic (ProhibitReturnSort)
    };

    foreach my $dir (@dir) {
        finddepth({
            $sort ? (preprocess => $preprocess) : (),
            wanted => $wanted,
        }, $dir);
    }
}

1;
