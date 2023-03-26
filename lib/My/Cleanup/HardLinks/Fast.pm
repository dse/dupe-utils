package My::Cleanup::HardLinks::Fast;
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../../../../lib";

use My::Progress;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub run {
    my ($self, @dir) = @_;

    my $progress = $self->{progress} ? My::Progress->new(
        enabled => 1,
        total2  => scalar @dir,
    ) : undef;

    my $wanted = sub {
        $progress->incr() if defined $progress;
        my @lstat = lstat($_);
        return unless scalar @lstat;
        if (-d _) {
            if (rmdir($_)) {
                $progress->clear() if defined $progress;
                warn("rmdir $File::Find::name\n") if $self->{verbose};
            }
            return;
        }
        if (!-f _) {
            return;
        }
        my (undef, undef, undef, $nlink) = @lstat;
        if ($nlink < 2) {
            return;
        }
        if ($self->{force}) {
            if (unlink($_)) {
                $progress->clear() if defined $progress && $self->{verbose};
                warn("rm $File::Find::name\n") if $self->{verbose};
            } else {
                $progress->clear() if defined $progress;
                warn("$File::Find::name: $!\n");
            }
        } else {
            $progress->clear() if defined $progress;
            warn("rm $File::Find::name\n");
        }
    };

    my $preprocess = sub {
        return sort @_;         ## no critic (ProhibitReturnSort)
    };

    foreach my $dir (@dir) {
        $progress->incr2() if scalar @dir > 1;
        finddepth({
            preprocess => $preprocess,
            wanted => $wanted,
        }, $dir);
    }
    $progress = undef;
}

1;
