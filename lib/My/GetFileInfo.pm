package My::GetFileInfo;
use warnings;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(get_file_info);

use File::Find qw(find);

sub get_file_info {
    my ($options, @args) = @_;
    my $sub = (ref $options eq 'HASH') ? $options->{sub} : (ref $options eq 'CODE') ? $options : undef;
    die("no subroutine specified") if !defined $sub || ref $sub ne 'CODE';

    if (!scalar @args) {
        push(@args, '-');
    }
    my @files = grep { -f $_ || $_ eq '-' } @args;
    my @dirs = grep { -d $_ } @args;
    get_file_info_via_find($sub, $options, $_) foreach @dirs;
    get_file_info_from_file($sub, $options, $_) foreach @files;
}

sub get_file_info_via_find {
    my ($sub, $options, $dir) = @_;
    my $wanted = sub {
        my @lstat = lstat($_);
        return unless @lstat;
        return if !-f _;
        my $dev = $lstat[0];
        my $ino = $lstat[1];
        my $size = $lstat[7];
        my $mtime = $lstat[9];
        my $dev_ino = "$dev,$ino";
        &$sub($dev, $ino, $size, $mtime, $File::Find::name);
    };
    find({ wanted => $wanted }, $dir);
}

sub get_file_info_from_file {
    my ($sub, $options, $file) = @_;
    my $fh;
    if ($file eq '-') {
        if (!open($fh, '<-')) {
            warn("stdin: $!");
            return;
        }
    } else {
        if (!open($fh, '<', $file)) {
            warn("$file: $!");
            return;
        }
    }
    while (<$fh>) {
        s{\R\z}{};
        my ($ver, @data) = split();
        next if $ver ne 'v1';
        my ($dev, $ino, $size, $mtime, $pathname) = @data;
        &$sub($dev, $ino, $size, $mtime, $pathname);
    }
    close($fh);
}

1;
