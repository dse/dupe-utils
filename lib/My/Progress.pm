package My::Progress;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;

use Time::HiRes qw(gettimeofday);

our $COLS;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{secs} //= 0.1;
    $self->{cols} //= ($COLS //= compute_cols());
    return $self;
}

sub incr {
    return if !-t 2;
    my ($self) = @_;
    return if !$self->{enabled};

    $self->{counter} //= 0;
    ++$self->{counter};

    my $now = gettimeofday();
    return if defined $self->{last} && $now < ($self->{last} + $self->{secs});
    $self->{last} = $now;

    my $line1 = '' . $self->{counter};
    $line1 .= "/" . $self->{total}    if defined $self->{total};
    $line1 .= " " . $self->{counter2} if defined $self->{counter2};
    $line1 .= "/" . $self->{total2}   if defined $self->{total2};
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
    return if !-t 2;
    my ($self) = @_;
    return if !$self->{enabled};

    $self->{counter2} //= 0;
    ++$self->{counter2};
}

sub clear {
    return if !-t 2;
    my ($self) = @_;
    return if !$self->{enabled};
    p("\r\e[K");
}

sub DESTROY {
    return if !-t 2;
    my ($self) = @_;
    return if !$self->{enabled};
    $self->clear();
}

sub p {
    my $af = STDERR->autoflush(1);
    my $str = shift;
    print STDERR (scalar @_ ? sprintf($str, @_) : $str);
    STDERR->autoflush($af);
}

sub compute_cols {
    return if !-t 2;
    my $size = `stty size`;
    return if !defined $size;
    my (undef, $cols) = split(' ', $size);
    $cols -= 1 if defined $cols;
    return $cols;
}

END {
    clear_progress();
}

1;
