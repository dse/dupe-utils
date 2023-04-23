package My::Cleanup::HardLinks::Fast;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../../../../lib";

use File::Find qw(finddepth);

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub run {
    my ($self, @dir) = @_;
    my $force = $self->{force};
    my $verbose = $self->{verbose};
    my $sort = $self->{sort};
    my $total_trees = scalar @dir;
    my $last;
    my $wanted = sub {
        my @lstat = lstat($_);
        return unless scalar @lstat;
        if (-d _) {
            if ($force) {
                if (rmdir($_)) {
                    if ($verbose) {
                        warn("rmdir $File::Find::name\n") if $verbose;
                    }
                }
            }
            return;
        }
        return if (!-f _);
        my $nlink = $lstat[3];
        return if ($nlink < 2);
        if ($force) {
            if (unlink($_)) {
                if ($verbose) {
                    warn("rm $File::Find::name\n");
                }
            } else {
                warn("$File::Find::name: $!\n");
            }
        } else {
            if ($verbose) {
                warn("rm $File::Find::name\n");
            }
        }
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
