package Modoi::Plugin::Filter::Request::BasicAuth;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use MIME::Base64;
use HTTP::Engine::Response;

sub init {
    my $self = shift;
    die 'username and password required' unless $self->config->{username} && $self->config->{password};
}

sub filter {
    my ($self, $req, $res_ref) = @_;

    my $auth_header = $req->header('Authorization');
    my $auth_expect = 'Basic ' . encode_base64($self->config->{username} . ':' . $self->config->{password}, '');

    if (!$auth_header || $auth_header ne $auth_expect) {
        $$res_ref = HTTP::Engine::Response->new;
        $$res_ref->status(401);
        $$res_ref->content('401 Unauthorized');
        $$res_ref->headers->header(WWW_Authenticate => 'Basic realm="Modoi"');
    }
}

1;
