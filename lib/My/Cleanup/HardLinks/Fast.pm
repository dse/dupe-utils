package My::Cleanup::HardLinks::Fast;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../../../../lib";

use File::Find qw(finddepth);
use Time::HiRes qw(gettimeofday);

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub run {
    my ($self, @dir) = @_;
    my $progress = -t 2 && $self->{progress};
    my $force = $self->{force};
    my $verbose = $self->{verbose};
    my $sort = $self->{sort};
    my $save_autoflush = $progress ? STDERR->autoflush(1) : undef;
    my $counter_found = 0;
    my $counter_rm = 0;
    my $counter_rmdir = 0;
    my $counter_trees = 0;
    my $total_trees = scalar @dir;
    my $last;
    my $wanted = sub {
        if ($progress) {
            ++$counter_found;
            my $now = gettimeofday();
            if (!defined $last || $now >= $last + 0.1) {
                printf STDERR ("\r%d found; tree %d of %d; %d f; %d d \e[K", $counter_found, $counter_trees, $total_trees, $counter_rm, $counter_rmdir);
                $last = $now;
            }
        }
        my @lstat = lstat($_);
        return unless scalar @lstat;
        if (-d _) {
            if ($force) {
                if (rmdir($_)) {
                    ++$counter_rmdir;
                    if ($verbose) {
                        print STDERR ("\r") if $progress && $verbose;
                        warn("rmdir $File::Find::name\n") if $verbose;
                    }
                }
            } else {
                ++$counter_rmdir;
            }
            return;
        }
        return if (!-f _);
        my $nlink = $lstat[3];
        return if ($nlink < 2);
        if ($force) {
            if (unlink($_)) {
                ++$counter_rm;
                if ($verbose) {
                    print STDERR "\r" if $progress;
                    warn("rm $File::Find::name\n");
                }
            } else {
                print STDERR "\r" if $progress;
                warn("$File::Find::name: $!\n");
            }
        } else {
            ++$counter_rm;
            if ($verbose) {
                print STDERR "\r" if $progress;
                warn("rm $File::Find::name\n");
            }
        }
    };

    my $preprocess = sub {
        return sort @_;         ## no critic (ProhibitReturnSort)
    };

    foreach my $dir (@dir) {
        ++$counter_trees if $progress;
        finddepth({
            $sort ? (preprocess => $preprocess) : (),
            wanted => $wanted,
        }, $dir);
    }

    print STDERR "\r" if $progress;
    STDERR->autoflush($save_autoflush) if $progress;
}

1;
