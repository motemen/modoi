package Modoi;
use strict;
use warnings;
use 5.8.8;
use UNIVERSAL::require;

our $VERSION = '0.01';

sub log {
    my ($self, $level, @msgs) = @_;
    printf STDERR "%-7s @msgs\n", "[$level]";
}

sub initialize { __PACKAGE__->_context }
sub _context { our $Modoi ||= Modoi::Context->new }

foreach my $method (qw(proxy fetcher install_component component)) {
    no strict 'refs';
    *$method = sub {
        my ($class, @args) = @_;
        return __PACKAGE__->_context->$method(@args);
    };
}

package Modoi::Context;
use Mouse;
use Modoi::Proxy;

has proxy => (
    is  => 'rw',
    isa => 'Modoi::Proxy',
    default => sub { Modoi::Proxy->new },
    handles => [ 'fetcher' ],
);

has installed_components => (
    is  => 'rw',
    isa => 'HashRef', # TODO HashRef[Modoi::Component]
    default => sub { +{} },
);

sub install_component {
    my ($self, $name) = @_;
    my $component_class = "Modoi::Component::$name";
    $component_class->require or die $@;
    return $self->{installed_components}->{$name} = $component_class->INSTALL($self);
}

sub component {
    my ($self, $name) = @_;
    $self->installed_components->{$name};
}

1;
