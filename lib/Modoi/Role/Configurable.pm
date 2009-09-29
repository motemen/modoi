package Modoi::Role::Configurable;
use Any::Moose '::Role';

use Modoi::Config;

requires 'DEFAULT_CONFIG';

has 'config', (
    is  => 'rw',
    isa => 'HashRef',
    builder => '_build_config',
);

sub _build_config {
    my $self  = shift;
    local $Modoi::Config::Caller = ref $self;
    package_config(default => $self->DEFAULT_CONFIG);
}

1;
