package Madoi::Server;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use LWP::UserAgent;
use HTTP::Engine;
use HTTP::Engine::Response;
use Madoi::HandleContent;

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

    Madoi->context->log(info => join ' ', 'handle request', $req->method, $req->request_uri);

    if (my $host = $req->header('Host')) {
        $self->serve_proxy($req);
    } else {
        $self->serve_internal($req);
    }
}

sub serve_proxy {
    my ($self, $req) = @_;

    my $_res;
    if (uc $req->method eq 'GET') {
        # TODO handle redirection
        if (my $fetch_res = Madoi->context->fetcher->fetch($req->request_uri)) {
            $_res = $fetch_res->http_response;
            $_res->code(200);
            $_res->content($fetch_res->content);
            $_res->header(Content_Type => $fetch_res->content_type);
        }
    }

    unless ($_res) {
        Madoi->context->log(debug => Madoi->context->fetcher . '->fetch failed');
        my $_req = $req->as_http_request;
           $_req->uri($req->request_uri);
        $_res = LWP::UserAgent->new->simple_request($_req)
    }

    Madoi::HandleContent->handle($_res); # XXX

    my $res = HTTP::Engine::Response->new;
       $res->set_http_response($_res);
    $res;
}

1;
