package Madoi::Plugin::HandleContent::ServeCacheOn404;
use strict;
use warnings;
use base qw(Madoi::Plugin);
use Storable;

sub filter {
    my ($self, $res) = @_;
    return unless $res->code == 404;

    my $cache = Madoi->context->fetcher->cache;
    my $entry = $cache->get($res->request->uri) or return;

    Madoi->context->log(info => 'serve cache for ' . $res->request->uri);

    $entry = Storable::thaw($entry);

    $res->code(200);
    $res->content($entry->{Content});
    $res->content_type($entry->{ContentType});
}

1;
