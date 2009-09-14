package Modoi::Server;
use Any::Moose;

use HTTP::Engine;
use AnyEvent;

has 'config', (
    is => 'rw',
);

has 'engine', (
    is  => 'rw',
    isa => 'HTTP::Engine',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_engine {
    my $self = shift;
    HTTP::Engine->new(
        interface => {
            module => 'AnyEvent',
            args   => $self->config,
            request_handler => sub { },
        }
    );
}

sub run {
    my $self = shift;
    $self->engine->run;
    AnyEvent->condvar->recv;
}

1;
