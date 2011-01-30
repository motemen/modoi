package Modoi;
use strict;
use warnings;
use 5.8.8;
use UNIVERSAL::require;
use Coro ();
use AnyEvent;
use Guard;
use Data::Dumper ();

our $VERSION = '0.01';

sub package_state {
    my $pkg = caller;
    return __PACKAGE__->context->_state->{$pkg} ||= {};
}

sub store_state {
    __PACKAGE__->context->store_state;
}

sub log {
    my ($self, $level, @args) = @_;
    my ($pkg, $filename) = caller;
    $pkg =~ s/^Modoi:://;
    $pkg = $filename if $filename =~ /\.psgi$/;
    printf STDERR "[%s] %-6s %s - %s\n",
        scalar(localtime), uc $level, $pkg,
        join ' ', map {
            local $Data::Dumper::Indent = 0;
            local $Data::Dumper::Maxdepth = 1;
            local $Data::Dumper::Terse = 1;
            !ref $_ || overload::Method($_, '""') ? "$_" : Data::Dumper::Dumper($_);
        } @args;
}

sub initialize {
    my $class = shift;
    foreach (@{$class->config->package_config->{components} || []}) {
        $class->install_component($_);
    }
}

sub context {
    require Modoi::Context;
    return our $Modoi ||= Modoi::Context->new;
}

foreach my $method (qw(proxy fetcher db internal install_component component config)) {
    no strict 'refs';
    *$method = sub {
        my ($class, @args) = @_;
        return __PACKAGE__->context->$method(@args);
    };
}

1;
