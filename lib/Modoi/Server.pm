package Modoi::Server;
use Any::Moose;
use Any::Moose 'X::Types::Path::Class';

use Modoi;
use Modoi::Proxy;

use AnyEvent;
use Coro;
use Coro::AnyEvent;

use HTTP::Engine;
use HTTP::Engine::Middleware;

use LWP::MediaTypes;
use Path::Class;
use HTTP::Status;

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

has 'root', (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    default => sub { dir('root') },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub handle_request {
    my ($self, $req) = @_;

    Modoi->log(debug => sprintf 'handle %s %s', $req->method, $req->request_uri);

    my $serve = $req->proxy_request ? 'serve_proxy' : 'serve_internal';

    my $res = HTTP::Engine::Response->new;
    eval {
        $self->$serve($req, $res);
    };
    if ($@) {
        $res->code(500);
        $res->content_type('text/plain');
        $res->content($@);
    }
    unless ($res->content) {
        $res->content($res->code . ' ' . status_message($res->code));
    }
    $res;
}

sub serve_proxy {
    my ($self, $req, $res) = @_;

    my $_req = $req->as_http_request;
    $_req->uri($req->request_uri);

    $res->set_http_response($self->proxy->process($_req));
}

sub serve_internal {
    my ($self, $req, $res) = @_;

    # XXX まったくてきとう

    if ($req->uri->path =~ qr<^/(?:status)?$>) {
        use Text::MicroTemplate::File;
        my $mt = Text::MicroTemplate::File->new(include_path => [ $self->root ]);
        my $file = $req->uri->path;
        $file =~ s</$></index>;
        $file =~ s<^/+><>;
        $res->content($mt->render_file("$file.mt", $self)->as_string);
    }
    elsif ($req->uri->path eq '/fetcher/cancel') {
        if (my $uri = $req->param('uri')) {
            $self->proxy->fetcher->cancel($uri);
            $res->code(302);
            $res->header(Location => '/status');
        }
    }
    else {
        die 'No route';
    }
}

# sub serve_static {
#     my ($self, $req, $res) = @_;
#     my $path = $req->uri->path;
#     $path =~ s<^/$></index.html>;
#     my $file = $self->root->file(split '/', $path);
#     if (-e $file) {
#         $res->content_type(guess_media_type("$file"));
#         $res->content(scalar $file->slurp);
#     } else {
#         $res->code(404);
#     }
# }

sub _build_middleware {
    my $self = shift;

    my $middleware = HTTP::Engine::Middleware->new;
    $middleware->install('HTTP::Engine::Middleware::ModuleReload');
    $middleware->install(
        'HTTP::Engine::Middleware::Static' => {
            regexp  => qr</css/.*>,
            docroot => $self->root,
        }
    );
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
