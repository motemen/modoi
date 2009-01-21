package Modoi::Plugin::Filter::Response::ServeCacheOn404;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Storable;

sub init {
    my ($self, $context) = @_;

    $context->register_hook(
        $self,
        'server.response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    return unless $res->code == 404;

    my $cache = Modoi->context->fetcher->cache;
    my $entry = $cache->get($res->request->uri) or return;

    Modoi->context->log(info => 'serve cache for ' . $res->request->uri);

    $entry = Storable::thaw($entry);

    $res->code(200);
    $res->content($entry->{Content});
    $res->content_type($entry->{ContentType});
    $res->push_header(X_Modoi_Fillter => 'Response-ServeCacheOn404');
}

1;
