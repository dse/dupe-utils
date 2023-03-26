package My::Progress;
## no critic (ProhibitInteractiveTest)
use warnings;
use strict;
use Time::HiRes qw(gettimeofday);
our $counter = 0;
our $total;
our $counter2;
our $total2;
our $cols;
our $enabled;
our $modulo = 173;
our $secs = 0.1;
use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(incr_progress cols_progress clear_progress);
my $last;
my $now;
sub incr_progress {
    return if !-t 2 || !$enabled;
    ++$counter;
    $now = gettimeofday();
    return if defined $last && $now < ($last + $secs);
    $last = $now;
    my $line1 = "$counter";
    $line1 .= "/$total" if defined $total;
    $line1 .= " $counter2" if defined $counter2;
    $line1 .= "/$total2" if defined $total2;
    if (!scalar @_) {
        return p("\r${line1}\e[K");
    }
    $line1 .= " ";
    my $str = shift;
    my $line2 = scalar @_ ? sprintf($str, @_) : $str;
    if (defined $cols) {
        my $pos = -($cols - length($line1) - 3);
        $line2 = substr($line2, $pos);
    }
    return p("\r${line1}${line2}\e[K");
}
sub clear_progress {
    return if !-t 2 || !$enabled;
    p("\r\e[K");
}
sub p {
    return if !-t 2 || !$enabled;
    my $af = STDERR->autoflush(1);
    my $str = shift;
    print STDERR (scalar @_ ? sprintf($str, @_) : $str);
    STDERR->autoflush($af);
}
sub cols_progress {
    return if !-t 2 || defined $cols;
    my $size = `stty size`;
    return if !defined $size;
    (undef, $cols) = split(' ', $size);
    $cols -= 1 if defined $cols;
}
END {
    clear_progress();
}
1;
