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

sub new_response {
    my $self = shift;
    require Modoi::Response;
    Modoi::Response->new(@_);
}

sub new_response_from_http_response {
    my ($self, $http_res) = @_;
    my $res = $self->new_response($http_res->code, $http_res->headers, $http_res->content);
    $res->_original_http_response($http_res);
    return $res;
}

1;
