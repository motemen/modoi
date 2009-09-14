package Modoi::CLI::Server;
use Any::Moose;

with any_moose('X::Getopt');

use Modoi::Server;

has 'port', (
    traits => [ 'Getopt' ],
    is  => 'rw',
    isa => 'Int',
    default => '3128',
);

has 'host', (
    traits => [ 'Getopt' ],
    is  => 'rw',
    isa => 'Str',
    default => '0.0.0.0',
);

has 'server', (
    is  => 'rw',
    isa => 'Modoi::Server',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_server {
    my $self = shift;
    Modoi::Server->new(config => { host => $self->host, port => $self->port });
}

sub run {
    my $self = shift;
    $self->server->run;
}

1;
