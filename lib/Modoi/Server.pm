package Modoi::Server;
use Any::Moose;

use Modoi::Proxy;
use HTTP::Engine;
use AnyEvent;

has 'config', (
    is => 'rw',
);

has 'engine', (
    is  => 'rw',
    isa => 'HTTP::Engine',
    lazy_build => 1,
);

has 'proxy', (
    is  => 'rw',
    isa => 'Modoi::Proxy',
    default => sub { Modoi::Proxy->new },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub handle_request {
    my ($self, $req) = @_;

    (my $host = $req->header('Host') || '') =~ s/:\d+$//;

    if ($host) {
        return $self->serve_proxy($req);
    } else {
    }
}

sub serve_proxy {
    my ($self, $req) = @_;

    my $_req = $req->as_http_request;
       $_req->uri($req->request_uri);

    my $_res = $self->proxy->_process($req->as_http_request);

    my $res = HTTP::Engine::Response->new;
       $res->set_http_response($_res);

    $res;
}

sub _build_engine {
    my $self = shift;
    HTTP::Engine->new(
        interface => {
            module => 'AnyEvent',
            args   => $self->config,
            request_handler => sub { $self->handle_request(@_) },
        }
    );
}

sub run {
    my $self = shift;
    $self->engine->run;
    AnyEvent->condvar->recv;
}

1;
