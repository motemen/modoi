package Modoi::Request;
use strict;
use warnings;
use parent 'Plack::Request';
use HTTP::Request;

sub is_proxy_request {
    my $self = shift;
    return $self->request_uri =~ m(^\w+://);
}

sub as_http_message {
    my $self = shift;
    return HTTP::Request->new(
        $self->method,
        $self->request_uri,
        $self->headers,
        $self->raw_body,
    );
}

1;
