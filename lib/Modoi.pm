package Modoi;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Path::Class;
use Modoi::Downloader;
use Modoi::Server;
require UNIVERSAL::require;

our @Components = qw(downloader server fetcher logger);

__PACKAGE__->mk_accessors(qw(config), @Components);

__PACKAGE__->mk_classdata('context');

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(ref $_[0] eq 'HASH' ? $_[0] : { @_ });

    $self->config({}) unless $self->config;
    $self->config->{plugin_path} ||= dir($FindBin::Bin, 'lib', 'Modoi', 'Plugin');
    $self->config->{server}->{host} ||= '';
    $self->config->{server}->{port} ||= 3128;

    $class->context($self);

    $self->init;

    $self;
}

sub init {
    my $self = shift;

    foreach (@Components) {
        my $module = __PACKAGE__ . '::' . ucfirst;
        $module->require or die $@;
        $self->$_($module->new(config => $self->config->{$_}));
    }

    $self->load_plugins;
}

sub bootstrap {
    my $class = shift;
    my $self = $class->new(@_);
    $self->run;
    $self;
}

sub run {
    shift->server->run;
}

sub log {
    my ($self, $level, $message) = @_;
    my ($pkg) = caller;
    $self->logger->log(level => $level, message => "[$level] $pkg $message\n");
}

sub load_plugins {
    my $self = shift;
    my $plugin_dir = $self->config->{plugin_path};
    unshift @INC, "$plugin_dir";

    foreach (@{$self->config->{plugins}}) {
        my $module = $_->{module};
        $module->require or die $@;
        $module =~ s/^(?!Modoi::Plugin::)/Modoi::Plugin::/;

        my $plugin = $self->{plugins}->{$module} = $module->new({ config => $_->{config} });
           $plugin->register($self);

        $self->log(info => "loaded plugin $_->{module}");
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