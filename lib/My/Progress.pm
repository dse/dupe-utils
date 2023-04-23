package My::Progress;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(progress);

use FindBin;
use lib "${FindBin::Bin}/../../lib";

use My::Tick qw(tick);

our $COLS;

our $tty;
our $clear = 1;
INIT {
    if (open($tty, '>', '/dev/tty')) {
        $COLS = compute_cols();
        $tty->autoflush(1);
    } else {
        undef $tty;             # force the issue
    }
}

sub printf_progress {
    return if !defined $tty;
    my ($str, @args) = @_;
    my $output = sprintf($str, @args);
    print_progress($output);
}

sub print_progress {
    return if !defined $tty;
    $clear = 0;
    my $output = join('', @_);
    if (defined $COLS && length($output) > $COLS) {
        $output = substr($output, 0, $COLS);
    }
    print $tty ("\r" . $output . "\e[K");
}

sub clear_progress {
    return if !defined $tty;
    return if $clear;
    $clear = 1;
    print $tty ("\r\e[K");
}

END {
    clear_progress();
}

# OO interface, so we can undef/leave scope and erase.

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

sub print {
    return if !defined $tty;
    my $self = shift;
    if ($self->{tick}) {
        return unless tick();
    }
    print_progress(@_);
};                              # the ';' keeps cperl-mode happy.

sub printf {
    return if !defined $tty;
    my $self = shift;
    if ($self->{tick}) {
        return unless tick();
    }
    printf_progress(@_);
};                              # the ';' keeps cperl-mode happy.

sub clear {
    return if !defined $tty;
    my $self = shift;
    clear_progress();
}

DESTROY {
    return if !defined $tty;
    my ($self) = @_;
    clear_progress();
}

sub compute_cols {
    return if !defined $tty;
    my $size = `stty size`;
    return if !defined $size;
    my (undef, $cols) = split(' ', $size);
    $cols -= 1 if defined $cols;
    return $cols;
}

1;
