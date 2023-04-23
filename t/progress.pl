#!/usr/bin/env perl
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../lib";
use My::Progress qw();

{
    my $progress = My::Progress->new(tick => 1);
    for (my $i = 0; $i < 10000000; $i += 1) {
        $progress->printf("  %d/%d", $i, 10000000);
    }
}

sleep(1);

{
    my $progress = My::Progress->new(tick => 0);
    for (my $i = 0; $i < 1000000; $i += 1) {
        $progress->printf("  %d/%d", $i, 1000000);
    }
}

sleep(1);
