package Modoi::Response;
use strict;
use warnings;
use parent 'Plack::Response';
use HTTP::Message::PSGI qw(res_from_psgi);

use Plack::Util::Accessor qw(_original_http_response data);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->data({});
    return $self;
}

sub as_http_message {
    res_from_psgi($_[0]->finalize);
}

sub from_http_response {
    my ($class, $http_res) = @_;
    my $self = $class->new($http_res->code, $http_res->headers, $http_res->content);
    $self->_original_http_response($http_res);
    return $self;
}

1;
