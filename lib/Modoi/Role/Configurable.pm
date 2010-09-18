package Modoi::Role::Configurable;
use Any::Moose '::Role';

use Modoi::Config;

requires 'DEFAULT_CONFIG';

has 'config', (
    is  => 'rw',
    isa => 'Modoi::Config::Object',
    lazy_build => 1,
);

use Any::Moose '::Util::TypeConstraints';

# FIXME やっぱり気持ちわるい気がしてきた
coerce class_type('Modoi::Config::Object')
    => from 'HashRef' => via { bless $_, 'Modoi::Config::Object' };

no Any::Moose;

sub _build_config {
    my $self  = shift;
    local $Modoi::Config::Caller = ref $self;
    return bless package_config(default => $self->DEFAULT_CONFIG), 'Modoi::Config::Object';
}

package Modoi::Config::Object;
use Modoi::Condition;

sub condition {
    my ($self, $name) = @_;
    return $self->{_condition_cache}->{$name} ||= Modoi::Condition->new($self->{$name} || {});
}

1;
