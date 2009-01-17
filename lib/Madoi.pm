package Madoi;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Path::Class;
require UNIVERSAL::require;

use Madoi::Server;
use Madoi::Downloader;

__PACKAGE__->mk_accessors(qw(config downloader server));

__PACKAGE__->mk_classdata('context');

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(ref $_[0] eq 'HASH' ? $_[0] : { @_ });

    $self->config({}) unless $self->config;
    $self->config->{plugin_path} ||= dir($FindBin::Bin, 'lib', 'Madoi', 'Plugin');
    $self->config->{downloader}->{store_dir} ||= dir($FindBin::Bin, 'store');
    $self->config->{server}->{port} ||= 3128;

    $class->context($self);

    $self->init;
    $self;
}

sub init {
    my $self = shift;
    $self->downloader(Madoi::Downloader->new(config => $self->config->{downloader}));
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

    $self->load_plugins; # TODO Move to init and add hook for server start

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
