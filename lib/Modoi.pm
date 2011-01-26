package Modoi;
use strict;
use warnings;
use 5.8.8;
use UNIVERSAL::require;
use Coro ();
use AnyEvent;
use Guard;
use Data::Dumper ();
use Script::State -datafile => '.modoi.state';

my $State;
BEGIN { script_state $State } # XXX

sub store_state {
    Modoi->log(info => 'storing state...');
    foreach (values %{ Modoi->_context->installed_components }) {
        $_->STORE_STATE;
    }
    Script::State->store;
}

END {
    __PACKAGE__->store_state;
}

our $VERSION = '0.01';

sub package_state {
    my $pkg = caller;
    return $State->{$pkg} ||= {};
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

sub _context { our $Modoi ||= Modoi::Context->new }

foreach my $method (qw(proxy fetcher db internal install_component component config)) {
    no strict 'refs';
    *$method = sub {
        my ($class, @args) = @_;
        return __PACKAGE__->_context->$method(@args);
    };
}

package Modoi::Context;
use Mouse;
use Modoi::Proxy;
use Modoi::DB;
use Modoi::Internal;
use Modoi::Config;

has proxy => (
    is  => 'rw',
    isa => 'Modoi::Proxy',
    default => sub { Modoi::Proxy->new },
    handles => [ 'fetcher' ],
);

has db => (
    is  => 'rw',
    isa => 'Modoi::DB',
    default => sub { Modoi::DB->new({ connect_info => [ 'dbi:SQLite:modoi.db' ] }) },
);

has internal => (
    is  => 'rw',
    isa => 'Modoi::Internal',
    default => sub { Modoi::Internal->new },
);

has config => (
    is  => 'rw',
    isa => 'Modoi::Config',
    default => sub { Modoi::Config->new },
);

has installed_components => (
    is  => 'rw',
    isa => 'HashRef[Modoi::Component]',
    default => sub { +{} },
);

sub install_component {
    my ($self, $name) = @_;

    if (my $component = $self->{installed_components}->{$name}) {
        Modoi->log(debug => "component '$name' is already installed");
        return $component;
    }

    my $component_class = "Modoi::Component::$name";
    $component_class->require or die $@;
    my $component = $self->{installed_components}->{$name} = $component_class->install($self);
    Modoi->log(info => "installed component '$name'");
    return $component;
}

sub component {
    my ($self, $name) = @_;
    $self->installed_components->{$name};
}

1;
