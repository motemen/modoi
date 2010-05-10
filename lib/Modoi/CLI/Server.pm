package Modoi::CLI::Server;
use Any::Moose;

with any_moose('X::Getopt::Strict');

use Modoi;
use Modoi::Config;
use Modoi::Server;

has 'config_file', (
    is  => 'rw',
    isa => 'Str',
    default => 'config.yaml',
    metaclass   => 'Getopt',
    cmd_flag    => 'config',
    cmd_aliases => [ 'c' ],
);

has 'extra_config', (
    is  => 'rw',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} },
    metaclass   => 'Getopt',
    cmd_aliases => [ 'o' ],
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

    my $extra_config;
    while (my ($key, $value) = each %{$self->extra_config}) {
        my @keys = split /\./, $key;
        my $c = $extra_config ||= {};
        $c = $c->{ shift @keys } ||= {} until @keys == 1;
        $c->{ shift @keys } = $value;
    }

    if (-e $self->config_file) {
        Modoi::Config->initialize_by_yaml_file($self->config_file, $extra_config);
    } else {
        Modoi::Config->initialize({}, $extra_config);
    }
}

sub setup_server {
    my $self = shift;

    if ($self->coro_debug_port) {
        Coro::Debug->require or die $@;
        our $coro_debug_server = Coro::Debug->new_tcp_server($self->coro_debug_port);
    }

    Modoi->context->server($self->server);
}

sub run {
    my $self = shift;

    $self->initialize_config;
    $self->setup_server;

    Modoi->context->server->run;
}

sub to_app {
    my $self = shift;

    $self->initialize_config;
    $self->setup_server;

    Modoi->context->server->as_psgi_app;
}

1;
