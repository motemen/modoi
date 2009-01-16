package Madoi::Plugin::HandleContent;
use strict;
use warnings;
use base qw(Madoi::Plugin HTTP::Proxy::BodyFilter);

sub register {
    my ($self, $context) = @_;
    $context->server->push_filter(
        response => $self
    );
}

1;
