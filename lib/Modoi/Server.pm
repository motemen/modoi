package Modoi::Server;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use URI;
use LWP::UserAgent;
use Path::Class;
use MIME::Types;
use HTTP::Date;
use HTTP::Engine;
use HTTP::Engine::Response;
use Modoi::Response;

__PACKAGE__->mk_accessors(qw(engine config static_dir template_dir));

sub new {
    my ($class, %args) = @_;
    my $config = delete $args{config};
    my $self = $class->SUPER::new(%args);
       $self->init_config($config);
       $self->setup_engine;
    $self;
}

sub init_config {
    my ($self, $config) = @_;
    $self->config($config);
    $self->static_dir(dir($self->config->{static_path}));
    $self->template_dir(dir($self->config->{template_path}));
}

sub root_uri {
    my $self = shift;
    $self->{_uri} ||= URI->new('http://' . $self->host_port . '/');
}

sub host_port {
    my $self = shift;
    $self->config->{name} . ':' . $self->config->{engine}->{port};
}

sub setup_engine {
    my $self = shift;

    $self->engine(
        HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args   => $self->config->{engine},
                request_handler => sub {
                    $self->handle_request(@_);
                },
            }
        )
    );
}

sub run {
    shift->engine->run;
}

sub handle_request {
    my ($self, $req) = @_;

    Modoi->context->log(debug => join ' ', 'handle request', $req->method, $req->request_uri);

    (my $host = $req->header('Host') || $self->config->{name} || '') =~ s/:\d+$//;

    my $res = eval {
        if ($host ne $self->config->{name}) {
            $self->serve_proxy($req);
        } else {
            $self->serve_internal($req);
        }
    };
    return $res if $res;

    my $error = $@;

    Modoi->context->log(error => $error);

    $res = HTTP::Engine::Response->new;
    $res->status(500);
    $res->body("<h1>Internal Server Error</h1><p>$error</p>");
    $res;
}

sub serve_proxy {
    my ($self, $req) = @_;

    my $_res;
    my $_req = $req->as_http_request;
       $_req->uri($req->request_uri);

    Modoi->context->run_hook('server.request', { request => $_req, response_ref => \$_res });

    if ($_res && $_res->isa('HTTP::Engine::Response')) {
        return $_res;
    }

    unless ($_res) {
        if (uc $req->method eq 'GET') {
            # TODO should handle redirection
            my $no_cache;
            if (($req->header('Pragma') || '') eq 'no-cache' ||
                ($req->header('Cache-Control') || '') eq 'no-cache' ||
                !$req->header('If-Modified-Since')) {
                $no_cache++;
            }
            if (my $fetch_res = Modoi->context->fetcher->request($req)) {
                $_res = $fetch_res->http_response;
                if (!$fetch_res->is_error && $no_cache) {
                    $_res->code(200);
                    $_res->content($fetch_res->content);
                    $_res->header(Content_Type => $fetch_res->content_type);
                    $_res->remove_header('Content-Encoding'); # XXX
                }
            }
        } else {
            $_res = LWP::UserAgent->new->simple_request($_req)
        }
    }

    Modoi->context->run_hook('server.response', { response => bless $_res, 'Modoi::Response' });

    Modoi->context->log(debug => sprintf '%s %s => %s', $req->method, $req->request_uri, $_res->code);

    my $res = HTTP::Engine::Response->new;
       $res->set_http_response($_res);
    $res;
}

sub serve_internal {
    my ($self, $req) = @_;
    my $uri = $req->uri;

    my @segments = $uri->path_segments;
    
    return $self->serve_static($req) if $segments[1] eq 'static';

    shift @segments;
    $segments[-1] =~ s/\.(\w+)$//;
    my $view = $1;

    my $engine = join '::', 'Modoi::Server::Engine', map { ucfirst ($_ || 'index') } @segments;
    unless ($engine->isa('Modoi::Server::Engine') || $engine->require) {
        my $res = HTTP::Engine::Response->new;
        $res->status(404);
        $res->content_type('text/plain');
        $res->body('404 Not Found');
        return $res;
    }
    $engine->new(view => $view, segments => \@segments)->_handle($req);
}

sub serve_static {
    my ($self, $req) = @_;

    my @segments = $req->uri->path_segments;
    splice @segments, 0, 2;

    my $file = $self->static_dir->file(@segments);

    my $res = HTTP::Engine::Response->new;

    if (-e $file) {
        my $size  = -s _;
        my $mtime = (stat _)[9];
        my ($ext) = $file =~ /\.(\w+)$/;

        $res->content_type(MIME::Types->new->mimeTypeOf($ext) || 'text/plain');

        if (my $if_modified_since = $req->headers->header('If-Modified-Since')) {
            my $time = HTTP::Date::str2time($if_modified_since);
            if ($mtime <= $time) {
                $res->status(304);
                return $res;
            }
        }

        $res->headers->header(Last_Modified => HTTP::Date::time2str($mtime));
        $res->headers->header(Content_Length => $size);
        $res->body(scalar $file->slurp);
    } else {
        $res->status(404);
        $res->content_type('text/plain');
        $res->body('404 Not Found');
    }

    $res;
}

{
    require HTTP::Server::Simple;
    no warnings 'redefine';

    *HTTP::Server::Simple::print_banner = sub {
        my $self = shift;
        Modoi->context->log(info => 'You can connect to your server at http://localhost:' . $self->port . '/');
    };
}

1;
