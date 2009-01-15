package Madoi::HTTP::Proxy::Filter;
use strict;
use warnings;
use base qw(HTTP::Proxy::BodyFilter Class::Accessor::Fast);
use Madoi::HandleContent;

__PACKAGE__->mk_accessors(qw(madoi));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->madoi({ @_ }->{madoi});
    $self;
}

sub filter {
    my $self = shift;
    my ($dataref, $message, $protocol, $buffer) = @_;
    Madoi::HandleContent->handle($self->madoi, @_);
}

1;
