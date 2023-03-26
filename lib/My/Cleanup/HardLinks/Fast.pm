package My::Cleanup::HardLinks::Fast;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../../../../lib";

use My::Progress;
use File::Find qw(finddepth);

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub run {
    my ($self, @dir) = @_;

    my $progress = $self->{progress} && -t 2 ? My::Progress->new(
        enabled => 1,
        total2 => ((scalar @dir > 1) ? (scalar @dir) : undef),
        suffix => 'files',
        suffix2 => 'trees',
        counter3 => 0,
        suffix3 => 'files rmed',
        counter4 => 0,
        suffix4 => 'dirs rmed',
    ) : undef;

    my $wanted = sub {
        $progress->incr($File::Find::name) if defined $progress;
        my @lstat = lstat($_);
        return unless scalar @lstat;
        if (-d _) {
            if (rmdir($_)) {
                $progress->incr4() if defined $progress;
                if ($self->{verbose}) {
                    $progress->clear() if defined $progress;
                    warn("rmdir $File::Find::name\n");
                }
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
                $progress->incr3() if defined $progress;
                if ($self->{verbose}) {
                    $progress->clear() if defined $progress;
                    warn("rm $File::Find::name\n");
                }
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
