package Modoi;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Path::Class;
require UNIVERSAL::require;

our @Components = qw(downloader server fetcher logger parser);

__PACKAGE__->mk_accessors(qw(config), @Components);

__PACKAGE__->mk_classdata('context');

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(ref $_[0] eq 'HASH' ? $_[0] : { @_ });

    $self->config({}) unless $self->config;
    $self->config->{plugin_path} ||= dir($FindBin::Bin, 'lib', 'Modoi', 'Plugin');
    $self->config->{server}->{engine}->{host} ||= '';
    $self->config->{server}->{engine}->{port} ||= 3128;
    $self->config->{server}->{name} ||= 'modoi';
    $self->config->{server}->{static_path} ||= dir($FindBin::Bin, 'static');
    $self->config->{server}->{template_path} ||= dir($FindBin::Bin, 'templates');

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
    $self->logger->log(level => $level, message => "[$$]$level: $pkg $message\n");
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
        $self->{plugins}->{"Modoi::Plugin::$filter"};
    } elsif (ref $filter eq 'Regexp') {
        map { $self->{plugins}->{$_} } grep { m/$filter/ } keys %{$self->{plugins}};
    } elsif (ref $filter eq 'CODE') {
        map { $self->{plugins}->{$_} } grep { $filter->($_) } keys %{$self->{plugins}};
    }
}

*plugin = \&plugins;

sub register_hook {
    my ($self, $plugin, %hooks) = @_;

    while (my ($hook, $callback) = each %hooks) {
        push @{$self->{hooks}->{$hook}}, {
            callback => $callback,
            plugin   => $plugin,
        };
    }
}

sub run_hook {
    my ($self, $hook, $args, $callback) = @_;

    my @ret;
    foreach my $action (@{$self->{hooks}->{$hook}}) {
        my $plugin = $action->{plugin};
        my $ret = $action->{callback}->($plugin, $self, $args);
        $callback->($ret) if $callback;
        push @ret, $ret;
    }
    return @ret;
}

1;
