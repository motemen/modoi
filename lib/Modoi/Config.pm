package Modoi::Config;
use strict;
use warnings;
use Exporter::Lite;
use Carp;
use Hash::Merge 'merge';

our @EXPORT    = qw(package_config);
our @EXPORT_OK = qw(config package_config);

our $Config = {};

our $Caller;

sub initialize {
    my $class = shift;
    $Config = $_[0] || {};
}

sub config () {
    $Config;
}

sub package_config (@) {
    my ($package) = $Caller || caller;
    $package =~ s/^Modoi:://;

    my $config = config->{lc $package} || {};

    if (@_ == 0) {
        $config;
    } elsif (@_ == 1) {
        $config->{$_[0]};
    } else {
        my %option = @_;
        merge +{ %$config }, $option{default};
    }
}

1;
