package Modoi::Context;
use Mouse;
use MouseX::Types::Path::Class;
use Modoi::Proxy;
use Modoi::DB;
use Modoi::Internal;
use Modoi::Config;

has proxy => (
    is  => 'rw',
    isa => 'Modoi::Proxy',
    default => sub { Modoi::Proxy->new },
    handles => [ 'fetcher' ],
);

has db => (
    is  => 'rw',
    isa => 'Modoi::DB',
    default => sub { Modoi::DB->new({ connect_info => [ 'dbi:SQLite:modoi.db' ] }) },
);

has internal => (
    is  => 'rw',
    isa => 'Modoi::Internal',
    default => sub { Modoi::Internal->new },
);

has config => (
    is  => 'rw',
    isa => 'Modoi::Config',
    default => sub { Modoi::Config->new },
);

has installed_components => (
    is  => 'rw',
    isa => 'HashRef[Modoi::Component]',
    default => sub { +{} },
);

has state_file => (
    is  => 'rw',
    isa => 'Path::Class::File',
    coerce => 1,
    lazy_build => 1,
);

sub install_component {
    my ($self, $name) = @_;

    if (my $component = $self->{installed_components}->{$name}) {
        Modoi->log(debug => "component '$name' is already installed");
        return $component;
    }

    my $component_class = "Modoi::Component::$name";
    $component_class->require or die $@;
    my $component = $self->{installed_components}->{$name} = $component_class->install($self);
    Modoi->log(info => "installed component '$name'");
    return $component;
}

sub component {
    my ($self, $name) = @_;
    $self->installed_components->{$name};
}

our $State;

sub _build_state_file {
    my $self = shift;
    return $self->config->package_config->{state_file} || '.modoi.state';
}

sub _state {
    my $self = shift;
    unless (defined $State) {
        $State = do { do $self->state_file; no strict 'vars'; $VAR1 } || {};
    }
    return $State;
}

sub store_state {
    my $self = shift;

    Modoi->log(info => 'storing state to', $self->state_file, '...');
    foreach (values %{ Modoi->context->installed_components }) {
        $_->STORE_STATE;
    }

    my $fh = $self->state_file->openw;
    print $fh Data::Dumper->new([ $State ])->Indent(1)->Purity(1)->Dump;
    close $fh;
}

1;
