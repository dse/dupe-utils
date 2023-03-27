package My::Tick;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;
use feature 'state';

use base 'Exporter';
our @EXPORT_OK = qw(tick);

use Time::HiRes qw(gettimeofday);

sub tick {
    state $last;
    my $now = gettimeofday();   # floating point
    if (!defined $last || $now >= $last + 0.1) {
        $last = $now;
        return 1;
    }
    return;
}

1;
