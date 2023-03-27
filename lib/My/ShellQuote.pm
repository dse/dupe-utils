package My::ShellQuote;
use warnings;
use strict;
use base 'Exporter';
our @EXPORT = qw();
our @EXPORT_OK = qw(shell_quote);
sub shell_quote {
    my ($string) = @_;
    for ($string) {
        # stolen from String::ShellQuote to reduce dependencies
        s/'/'\\''/g;
        s|((?:'\\''){2,})|q{'"} . (q{'} x (length($1) / 4)) . q{"'}|ge;
        $_ = "'$_'";
        s/^''//;
        s/''$//;
    }
    return $string;
}
1;
