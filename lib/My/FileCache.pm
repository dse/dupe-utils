package My::FileCache;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(cache_open cache_close cache_close_all);

use Fcntl qw(SEEK_CUR SEEK_SET);

our $maxopen;
BEGIN {
    my $fh;
    local $_;
    local $.;
    if (open($fh, '<', '/usr/include/sys/param.h')) {
        while (<$fh>) {
            if (/^\s*#\s*define\s+NOFILE\s+(\d+)/) {
                $maxopen = $1 - 4;
                close($fh);
                last;
            }
        }
        close($fh);
    }
    $maxopen //= 16;
}

our %seq;
our %fh;
our %ofs;
our $seq = 0;

sub cache_open {
    my ($file) = @_;
    if ($fh{$file}) {
        $seq{$file}++;
        return $fh{$file};
    }
  tryagain:
    if (scalar keys %fh > $maxopen - 1) {
        # least recently used to most recently used
        my @lru = sort { $seq{$a} <=> $seq{$b} } keys %fh;
        $seq = 0;
        # keep most recently used files
        my @keep = splice(@lru, int($maxopen / 3) || $maxopen);
        foreach my $keep (@keep) {
            $seq{$keep} = $seq++;
        }
        foreach my $lru (@lru) {
            $ofs{$lru} = sysseek($fh{$lru}, 0, SEEK_CUR);
            close($fh{$lru});
            delete $fh{$lru};
        }
    }
    my $fh;
    if (!open($fh, '<:raw', $file)) {
        $fh = undef;
        if ($!{EMFILE} || $!{ENFILE}) { # see open(2)
            if ($maxopen >= 8) {
                $maxopen -= 4;
                goto tryagain;
            } else {
                croak("$file: $! (too few open files)");
            }
        }
        croak("$file: $!");
    }
    $fh{$file} = $fh;
    $seq{$file} = ++$seq;
    if (defined $ofs{$file}) {
        my $ofs = sysseek($fh{$file}, $ofs{$file}, SEEK_SET);
        if (!defined $ofs || $ofs != $ofs{$file}) {
            cache_close($file);
            return;
        }
    }
    return $fh;
}

sub cache_close {
    my ($file) = @_;
    return if !exists $fh{$file};
    close($fh{$file}) if defined $fh{$file};
    delete $ofs{$file};
    delete $fh{$file};
    delete $seq{$file};
}

sub cache_close_all {
    foreach my $file (keys %fh) {
        close($fh{$file}) if defined $fh{$file};
    }
    %ofs = ();
    %fh = ();
    %seq = ();
}

1;
