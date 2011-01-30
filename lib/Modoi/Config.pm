package Modoi::Config;
use Mouse;
use MouseX::Types::Path::Class;
use YAML::Syck;

$YAML::Syck::ImplicitTyping = 1;

has config_file => (
    is  => 'rw',
    isa => 'Path::Class::File',
    default => 'config.yaml',
    coerce  => 1,
    lazy    => 1,
);

has _config => (
    is  => 'rw',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build__config {
    my $self = shift;
    return YAML::Syck::LoadFile($self->config_file);
}

sub package_config {
    my $self = shift;
    my $pkg  = shift || caller;
    $pkg =~ s/^Modoi:://;
    return $self->_config->{$pkg} ||= {};
}

1;
