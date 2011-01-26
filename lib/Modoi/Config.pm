package Modoi::Config;
use Mouse;
use MouseX::Types::Path::Class;
use YAML::Tiny;

has config_file => (
    is  => 'rw',
    isa => 'Path::Class::File',
    default => 'config.yaml',
    coerce  => 1,
);

has _config => (
    is  => 'rw',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build__config {
    my $self = shift;
    return YAML::Tiny->new->read($self->config_file)->[0];
}

sub package_config {
    my $self = shift;
    my $pkg = caller;
    $pkg =~ s/^Modoi:://;
    return $self->_config->{$pkg} || {};
}

1;
