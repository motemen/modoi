package Modoi::Config;
use strict;
use warnings;
use Carp;

our @EXPORT    = qw(package_config);
our @EXPORT_OK = qw(config package_config);

our $Config = {};

our $Caller;

sub import {
    if (@_ > 1 && ref $_[-1] eq 'HASH') {
        $_[0]->initialize(pop);
    }
    require Exporter::Lite;
    goto \&Exporter::Lite::import;
}

sub initialize {
    my $class = shift;
    foreach (@_) {
        $Config = _merge($Config, $_);
    }
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
        _merge($config, $option{default});
    }
}

sub _merge {
    my ($this, $that) = @_;
    return $that unless defined $this;
    return $this unless ref $that eq 'HASH';

    my %merged = (%$this, %$that);
    foreach (keys %merged) {
        $merged{$_} = _merge($this->{$_}, $that->{$_});
    }
    \%merged;
}

1;

__END__

=head1 NAME

Modoi::Config - modoi のグローバルなコンフィグ
