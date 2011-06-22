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

sub modify_content {
    my ($self, $code) = @_;

    local $_ = $self->as_http_message->decoded_content;
    $code->();

    my $content = $_;
    utf8::encode $content;

    my $content_type = $self->content_type;
       $content_type =~ s/(;.+)?$/; charset=utf-8/;

    $self->headers->remove_content_headers;
    $self->content($content);
    $self->content_type($content_type);
    $self->content_length(length $content);
}

1;
