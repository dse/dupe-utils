#!/usr/bin/env perl
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use FindBin;
use lib "${FindBin::Bin}/../lib";
use My::Progress qw();

{
    my $progress = My::Progress->new(tick => 1);
    for (my $i = 0; $i < 1e7; $i += 1) {
        $progress->printf("  %d/%d", $i, 1e7);
    }
    $progress->printf("  %d/%d\n", 1e7, 1e7);
}

sleep(1);

{
    my $progress = My::Progress->new(tick => 0);
    for (my $i = 0; $i < 1e6; $i += 1) {
        $progress->printf("  %d/%d", $i, 1e6);
    }
    $progress->printf("  %d/%d\n", 1e6, 1e6);
}

sleep(1);
