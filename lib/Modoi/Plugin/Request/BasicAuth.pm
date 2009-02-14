package Modoi::Plugin::Request::BasicAuth;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use MIME::Base64;
use HTTP::Engine::Response;

sub init {
    my ($self, $context) = @_;

    unless ($self->config->{username} && $self->config->{password}) {
        $context->log(error => 'username and password required');
    } else {
        $context->register_hook(
            $self,
            'server.request' => \&filter_request,
        );
    }
}

sub filter_request {
    my ($self, $context, $args) = @_;

    my $req = $args->{request};
    my $res_ref = $args->{response_ref};

    my ($auth_header) = $req->remove_header('Authorization');
    my $auth_expect = 'Basic ' . encode_base64($self->config->{username} . ':' . $self->config->{password}, '');

    if (!$auth_header || $auth_header ne $auth_expect) {
        $$res_ref = HTTP::Engine::Response->new;
        $$res_ref->status(401);
        $$res_ref->content('401 Unauthorized');
        $$res_ref->headers->header(WWW_Authenticate => 'Basic realm="Modoi"');
    }
}

1;
