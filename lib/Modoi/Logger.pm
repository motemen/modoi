package Modoi::Logger;
use strict;
use warnings;
use base qw(Log::Dispatch Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(config));

sub new {
    my ($class, %args) = @_;
    my $config = delete $args{config};
    my $self = $class->SUPER::new(%args);
       $self->init_config($config);
    $self;
}

sub init_config {
    my ($self, $config) = @_;

    return unless $config;

    $self->config($config);

    foreach (@$config) {
        my $module = "Log::Dispatch::$_->{module}";
        $module->require or die $@;

        my %args = %{$_->{config} || { }};
        $args{name} ||= lc $_->{module};

        $self->add($module->new(%args));
    }
}

1;
