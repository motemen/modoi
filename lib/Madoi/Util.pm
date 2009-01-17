package Madoi::Util;
use strict;
use warnings;
use base qw(Exporter::Lite);
use FindBin;
use Path::Class;

our @EXPORT_OK = qw(absolutize ensure_dir);

sub absolutize {
    my ($which, $path) = (@_ == 1 ? ('file', @_) : @_);
    ($which eq 'dir' ? \&dir : \&file)->($FindBin::Bin, $path);
}

sub ensure_dir {
    my $path = shift;
    $path = $path->parent if ref $path eq 'Path::Class::File';
    $path = dir($path) unless ref $path;

    my @dirs = ();
    do { unshift @dirs, $path } until -d ($path = $path->parent);

    -d or mkdir $_ or die "Could not mkdir $_" foreach @dirs;
}

1;
