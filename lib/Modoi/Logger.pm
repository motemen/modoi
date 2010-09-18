package Modoi::Logger;
use Any::Moose;
use Log::Dispatch::Config;

with 'Modoi::Role::Configurable';

sub DEFAULT_CONFIG {
    +{
        dispatchers => [ 'screen' ], 
        screen => {
            class     => 'Log::Dispatch::Screen',
            min_level => 'info',
            stderr    => 1,
            format    => '[%p] %m',
        },
    };
}

has 'logger', (
    is  => 'rw',
    isa => 'Log::Dispatch',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub log {
    my ($self, $level, $message) = @_;
    $message .= "\n" unless $message =~ /\n$/;
    $self->logger->log(level => $level, message => "$message");
}

sub _build_logger {
    my $self = shift;
    Log::Dispatch::Config->configure(Log::Dispatch::Configurator::HASH->new($self->config));
    return Log::Dispatch::Config->instance;
}

package Log::Dispatch::Configurator::HASH;
use base 'Log::Dispatch::Configurator';

sub new {
    my ($class, $hash) = @_;
    return bless $hash, $class;
}

sub get_attrs_global {
    my $self = shift;
    return +{ format => undef, dispatchers => $self->{dispatchers} || [] };
}

sub get_attrs {
    my ($self, $name) = @_;
    return $self->{$name};
}

1;
