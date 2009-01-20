package Modoi::Plugin::Filter::Request::ServeCache;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Storable;
use HTTP::Engine::Response;

sub filter {
    my ($self, $req, $res_ref) = @_;

    my $uri = $req->uri;
    my $cache = Modoi->context->fetcher->cache;
    my $entry = $cache->get($uri) or return;
       $entry = Storable::thaw($entry);

    # XXX currently support only content_type
    if (my $content_type = $self->config->{content_type}) {
        $content_type = quotemeta $content_type;
        $content_type =~ s/\\\*/\\w+/g;

        if ($entry->{ContentType} =~ /$content_type/) {
            Modoi->context->log(info => "serve cache for $uri");

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

1;
