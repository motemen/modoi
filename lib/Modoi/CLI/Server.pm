package Modoi::CLI::Server;
use Any::Moose;

with any_moose('X::Getopt::Strict');

use Modoi;
use Modoi::Config;
use Modoi::Server;

use YAML;

has 'config_file', (
    is  => 'rw',
    isa => 'Str',
    default => 'config.yaml',
    metaclass   => 'Getopt',
    cmd_flag    => 'config',
    cmd_aliases => [ 'c' ],
);

has 'coro_debug_port', (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    metaclass => 'Getopt',
    cmd_flag  => 'coro-debug-port',
);

has 'server', (
    is  => 'rw',
    isa => 'Modoi::Server',
    default => sub { Modoi::Server->new },
    lazy    => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub initialize_config {
    my $self = shift;
    Modoi::Config->initialize(YAML::LoadFile $self->config_file);
}

sub run {
    my $self = shift;

    if ($self->coro_debug_port) {
        Coro::Debug->require or die $@;
        our $coro_debug_server = Coro::Debug->new_tcp_server($self->coro_debug_port);
    }

    $self->initialize_config;

    Modoi->context->server($self->server);
    Modoi->context->server->run;
}

1;
