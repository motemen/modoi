package Madoi;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
require UNIVERSAL::require;
use Madoi::Server;

__PACKAGE__->mk_accessors(qw(config server));

sub new {
    my ($class, %option) = @_;
    my $self = bless {
        config => $option{config}
    }, $class;
}

sub bootstrap {
    my $class = shift;
    my $self = $class->new(@_);
    $self->run;
    $self;
}

sub run {
    my $self = shift;

    $self->server(
        Madoi::Server->new(
            %{$self->config->{server}},
            madoi => $self,
        )
    );

    $self->load_plugins;

    $self->server->start;
}

sub load_plugins {
    my $self = shift;
    my $plugin_dir = $self->config->{plugin_path};
    unshift @INC, "$plugin_dir";

    foreach (@{$self->config->{plugins}}) {
        my $module = $_->{module};
        $module->require or die $@;
        $module =~ s/^(?!Madoi::Plugin::)/Madoi::Plugin::/;
        my $plugin = $self->{plugins}->{$module} = $module->new({ config => $_->{config} });
        $plugin->register($self);
    }
}

sub plugins {
    my ($self, $filter) = @_;
    return values %{$self->{plugins}} unless $filter;

    if (not ref $filter) {
        map { $self->{plugins}->{$_} } grep /::\Q$filter\E::/, keys %{$self->{plugins}};
    }
}

1;
