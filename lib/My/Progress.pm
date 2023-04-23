package My::Progress;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use Time::HiRes qw(gettimeofday);

our $COLS;

our $tty;
BEGIN {
    if (!open($tty, '>', '/dev/tty')) {
        undef $tty;             # force the issue
    } else {
        $tty->autoflush(1);
    }
}

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{secs} //= 0.1;
    $self->{cols} //= ($COLS //= compute_cols());
    return $self;
}

sub incr {
    return if !defined $tty;
    my $self = shift;
    return if !$self->{enabled};

    $self->{counter} //= 0;
    ++$self->{counter};

    my $now = gettimeofday();
    return if defined $self->{last} && $now < ($self->{last} + $self->{secs});
    $self->{last} = $now;

    my $line1 = '' . $self->{counter};
    $line1 .= "/" . $self->{total}    if defined $self->{total};
    $line1 .= " " . $self->{suffix}   if defined $self->{suffix};

    $line1 .= " " . $self->{counter2} if defined $self->{counter2};
    $line1 .= "/" . $self->{total2}   if defined $self->{total2};
    $line1 .= " " . $self->{suffix2}  if defined $self->{suffix2};

    $line1 .= " " . $self->{counter3} if defined $self->{counter3};
    $line1 .= "/" . $self->{total3}   if defined $self->{total3};
    $line1 .= " " . $self->{suffix3}  if defined $self->{suffix3};

    $line1 .= " " . $self->{counter4} if defined $self->{counter4};
    $line1 .= "/" . $self->{total4}   if defined $self->{total4};
    $line1 .= " " . $self->{suffix4}  if defined $self->{suffix4};

    if (!scalar @_) {
        return p("\r${line1}\e[K");
    }
    $line1 .= " ";
    my $str = shift;
    my $line2 = scalar @_ ? sprintf($str, @_) : $str;
    if (defined $self->{cols}) {
        my $pos = -($self->{cols} - length($line1) - 3);
        $line2 = substr($line2, $pos);
    }
    return p("\r${line1}${line2}\e[K");
}

sub incr2 {
    return if !defined $tty;
    my ($self) = @_;
    return if !$self->{enabled};

    $self->{counter2} //= 0;
    ++$self->{counter2};
}

sub incr3 {
    return if !defined $tty;
    my ($self) = @_;
    return if !$self->{enabled};

    $self->{counter3} //= 0;
    ++$self->{counter3};
}

sub incr4 {
    return if !defined $tty;
    my ($self) = @_;
    return if !$self->{enabled};

    $self->{counter4} //= 0;
    ++$self->{counter4};
}

sub clear {
    return if !defined $tty;
    my ($self) = @_;
    return if !$self->{enabled};
    p("\r\e[K");
}

sub DESTROY {
    return if !defined $tty;
    my ($self) = @_;
    return if !$self->{enabled};
    $self->clear();
}

sub p {
    return if !defined $tty;
    my $str = shift;
    print $tty (scalar @_ ? sprintf($str, @_) : $str);
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
