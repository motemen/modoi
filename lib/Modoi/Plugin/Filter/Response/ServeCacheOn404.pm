package Modoi::Plugin::Filter::Response::ServeCacheOn404;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Storable;

sub filter {
    my ($self, $res) = @_;
    return unless $res->code == 404;

    my $cache = Modoi->context->fetcher->cache;
    my $entry = $cache->get($res->request->uri) or return;

    Modoi->context->log(info => 'serve cache for ' . $res->request->uri);

    $entry = Storable::thaw($entry);

    $res->code(200);
    $res->content($entry->{Content});
    $res->content_type($entry->{ContentType});
}

1;