package Modoi::Server;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use LWP::UserAgent;
use HTTP::Engine;
use HTTP::Engine::Response;

__PACKAGE__->mk_accessors(qw(madoi engine));

sub new {
    my ($class, %args) = @_;
    my $config = delete $args{config};
    my $self = $class->SUPER::new(%args);
       $self->setup_engine($config);
    $self;
}

sub setup_engine {
    my ($self, $args) = @_;

    $self->engine(
        HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args   => $args,
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

    if (my $host = $req->header('Host')) {
        $self->serve_proxy($req);
    } else {
        $self->serve_internal($req);
    }
}

sub serve_proxy {
    my ($self, $req) = @_;

    my $_res;

    foreach (Modoi->context->plugins('Filter::Request')) {
        $_->filter($req, \$_res);
    }

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
                }
            }
        } else {
            my $_req = $req->as_http_request;
               $_req->uri($req->request_uri);
            $_res = LWP::UserAgent->new->simple_request($_req)
        }
    }

    foreach (Modoi->context->plugins('Filter::Response')) {
        $_->filter($_res);
    }

    my $res = HTTP::Engine::Response->new;
       $res->set_http_response($_res);
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
