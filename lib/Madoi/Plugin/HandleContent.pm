package Madoi::Plugin::HandleContent;
use strict;
use warnings;
use base qw(Madoi::Plugin HTTP::Proxy::BodyFilter);

sub register {
    my ($self, $context) = @_;
    $context->server->push_filter(
        mime     => $self->mime_type,
        response => $self,
    );
}

sub mime_type { 'text/*' }

1;
