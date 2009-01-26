package Modoi::Plugin::ServeCache;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Storable;
use HTTP::Engine::Response;

sub init {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'server.request'  => \&filter_request,
        'server.response' => \&filter_response,
    );
}

sub filter_request {
    my ($self, $context, $args) = @_;

    my $req = $args->{request};
    my $res_ref = $args->{response_ref};

    my $uri = $req->uri;
    my $cache = $context->fetcher->cache;
    my $entry = $cache->get($uri) or return;
       $entry = Storable::thaw($entry);

    # XXX currently support only content_type
    if (my $content_type = $self->config->{content_type}) {
        $content_type = quotemeta $content_type;
        $content_type =~ s/\\\*/\\w+/g;

        if ($entry->{ContentType} =~ /$content_type/) {
            $context->log(info => "serve cache for $uri");

            $$res_ref = HTTP::Engine::Response->new;
            $$res_ref->headers->header(Content_Type => $entry->{ContentType});
            $$res_ref->headers->push_header(X_Modoi_Fillter => 'Request-ServeCache');

            if ($req->header('If-Modified-Since') || $req->header('If-None-Match')) {
                $$res_ref->status(304);
            } else {
                $$res_ref->status(200);
                $$res_ref->content($entry->{Content});
            }
        }
    }
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    return unless $res->is_error;

    my $cache = $context->fetcher->cache;
    my $entry = $cache->get($res->request->uri) or return;

    $context->log(info => 'serve cache for ' . $res->request->uri);

    $entry = Storable::thaw($entry);

    $res->code(200);
    $res->content($entry->{Content});
    $res->content_type($entry->{ContentType});
}

1;
