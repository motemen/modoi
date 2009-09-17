package Modoi::Server;
use Any::Moose;

use Modoi;
use Modoi::Proxy;

use AnyEvent;
use Coro;
use Coro::AnyEvent;

use HTTP::Engine;
use HTTP::Engine::Middleware;

has 'config', (
    is => 'rw',
);

has 'engine', (
    is  => 'rw',
    isa => 'HTTP::Engine',
    lazy_build => 1,
);

has 'middleware', (
    is  => 'rw',
    isa => 'HTTP::Engine::Middleware',
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

    Modoi->log(debug => sprintf 'handle %s %s', $req->method, $req->request_uri);
    $self->serve_proxy($req);
}

sub serve_proxy {
    my ($self, $req) = @_;

    my $_req = $req->as_http_request;
    $_req->uri($req->request_uri);

    my $res = HTTP::Engine::Response->new;
    $res->set_http_response($self->proxy->process($_req));
    $res;
}

sub _build_middleware {
    my $self = shift;

    my $middleware = HTTP::Engine::Middleware->new;
#   $middleware->install(qw(HTTP::Engine::Middleware::DebugRequest HTTP::Engine::Middleware::ModuleReload));
#   $middleware->instance_of('HTTP::Engine::Middleware::DebugRequest')->logger(sub { warn @_ });
    $middleware->install(qw(HTTP::Engine::Middleware::ModuleReload));
    $middleware
}

sub _build_engine {
    my $self = shift;

    HTTP::Engine->new(
        interface => {
            module => 'AnyEvent',
            args   => $self->config,
            request_handler => $self->request_handler,
        }
    );
}

sub request_handler {
    my $self = shift;
    my $handler = $self->middleware->handler(sub { $self->handle_request(@_) });
    unblock_sub {
        my ($req, $cb) = @_;
        my $res = $handler->($req);
        $cb->($res);
    };
}

sub run {
    my $self = shift;
    $self->engine->run;
    AnyEvent->condvar->wait;
}

1;
