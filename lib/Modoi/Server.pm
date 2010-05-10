package Modoi::Server;
use Any::Moose;
use Any::Moose 'X::Types::Path::Class';

use Modoi;
use Modoi::Config;
use Modoi::Proxy;
use Modoi::DB::Thread;

use AnyEvent;
use Coro;
use Coro::AnyEvent;

use Plack::Request;
use Plack::Builder;

use Text::MicroTemplate 'encoded_string';
use Text::MicroTemplate::File;

use Encode;
Encode->import('is_utf8');

use Path::Class;
use HTTP::Status;

with 'Modoi::Role::Configurable';

sub DEFAULT_CONFIG {
    +{ host => '0.0.0.0' };
}

has 'proxy', (
    is  => 'rw',
    isa => 'Modoi::Proxy',
    default => sub { Modoi::Proxy->new },
);

has 'root', (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    default => sub { dir('root') }, # TODO
);

has 'mt', (
    is  => 'rw',
    isa => 'Text::MicroTemplate::File',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub BUILD {
    my $self = shift;
    Modoi->context->server($self) unless Modoi->context->server;
}

sub handle_request {
    my ($self, $env, @args) = @_;

    my $req = Plack::Request->new($env);

    Modoi->log(debug => sprintf 'handle %s %s', $req->method, $req->request_uri);

    my $serve = $req->request_uri =~ m<^https?://> ? 'serve_proxy' : 'serve_internal';

    my $res = $req->new_response(200);
    eval {
        $self->$serve($req, $res);
    };
    if (my $error = $@) {
        chomp $error;
        Modoi->log(error => $error);
        $res->code(500);
        $res->content_type('text/plain; charset=utf8');
        $res->content(Encode::is_utf8($error) ? encode_utf8($error) : $error);
    }
    unless ($res->content) {
        $res->content($res->code . ' ' . status_message($res->code));
    }

    $res->finalize;
}

sub serve_proxy {
    my ($self, $req, $res) = @_;

    my $http_req = HTTP::Request->new(
        $req->method,
        $req->request_uri,
        $req->headers,
        $req->content,
    );

    my $http_res = $self->proxy->process($http_req);
    $res->code($http_res->code);
    $res->content($http_res->content);
    $res->headers($http_res->headers);
}

our @Route = (
    '/status'  => \&serve_status,
    '/threads' => \&serve_threads,
    '/proxy'   => \&serve_rewriting_proxy,
);

sub serve_internal {
    my ($self, $req, $res) = @_;

    # XXX まったくてきとう

    my @route = @Route;
    while (my ($path, $handler) = splice @route, 0, 2) {
        if ($req->uri->path eq $path) {
            $self->$handler($req, $res);
            return;
        }
    }

    die 'No route';
}

sub render_html {
    my ($self, $file) = splice @_, 0, 2;
    $self->mt->render_file("$file.mt", @_)->as_string;
}

sub serve_rewriting_proxy {
    my ($self, $req, $res) = @_;

    my $uri = $req->uri; # e.g. http://modoi:3128/proxy?http://img.2chan.nent/b/

    my $_req = $req->as_http_request;
    $_req->uri($uri->query);
    $_req->uri('http://' . $_req->uri) unless $_req->uri =~ m<^\w+://>;

    my $_res = $self->proxy->process($_req);
    if (($_res->header('Content-Type') || '') eq 'text/html') {
        if ($req->header('User-Agent') =~ /iPhone/) {
            # XXX experimental
            my $page   = Modoi->context->pages->classify($_res) or last;
            my $parsed = Modoi->context->parser->parse($_res)   or last;
            my $view   = do { require Modoi::View::iPhone; Modoi::View::iPhone->new(mt => $self->mt) };
            my $content = $view->render($page, $parsed);
            $_res->content(is_utf8($content) ? encode_utf8($content) : $content);
        }
        $self->proxy->rewrite_links(
            $_res, sub {
                $uri->query($_);
                "$uri";
            }
        );
    }

    $res->set_http_response($_res);
}

sub serve_status {
    my ($self, $req, $res) = @_;
    $res->content($self->render_html('status'));
}

sub serve_threads {
    my ($self, $req, $res) = @_;
    my $threads = Modoi::DB::Thread::Manager->get_threads(
        sort_by => 'updated_on DESC',
        limit   => 50,
        offset  => (($req->param('page') || 1) - 1) * 50,
    );
    $res->content($self->render_html('threads', $threads));
}

sub _build_mt {
    my $self = shift;
    Text::MicroTemplate::File->new(include_path => [ $self->root ]);
}

sub as_psgi_app {
    my $self = shift;

    my $app = sub {
        my ($env, @args) = @_;

        $env->{'psgi.nonblocking'} or die 'psgi.nonblocking feature requied';

        return sub {
            my $respond = shift;
            my $cv = AnyEvent->condvar;
            async {
                my $res = $self->handle_request($env, @args);
                $cv->send($res);
            };
            $cv->cb(sub {
                $respond->($cv->recv)
            });
        };
    };

    if (my $middlewares = $self->config->{middlewares}) {
        my $builder = Plack::Builder->new;
        foreach (@$middlewares) {
            $builder->add_middleware($_->{module}, %{$_->{args} || {}});
        }
        $app = $builder->to_app($app);
    }

    $app;
}

sub run {
    my $self = shift;

    require Plack::Loader;
    Plack::Loader->load(
        'AnyEvent::HTTPD', %{$self->config},
    )->run($self->as_psgi_app);
}

1;
