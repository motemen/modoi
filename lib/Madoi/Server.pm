package Madoi::Server;
use strict;
use warnings;
use base qw(HTTP::Proxy Class::Accessor::Fast);
use HTTP::Proxy::BodyFilter::complete;
use Madoi::HTTP::Proxy::Filter;

__PACKAGE__->mk_accessors(qw(madoi));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->madoi({ @_ }->{madoi});
    $self->push_filter(
        mime     => '*/*',
        response => HTTP::Proxy::BodyFilter::complete->new
    );
    $self;
}

1;
