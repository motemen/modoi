use strict;
use Test::More tests => 7;
use HTTP::Response;
use HTTP::Request::Common;
use Storable;
use Cache::Memory;
use Modoi;

my $module = 'Modoi::Plugin::Filter::ServeCache';

use_ok $module;

use FindBin;
Modoi->new;
Modoi->context->fetcher->cache(Cache::Memory->new);

my $plugin = $module->new;

my $uri = 'http://www.example.com/';
my $res = HTTP::Response->new(404);
$res->request(GET $uri);
$plugin->filter_response(Modoi->context, { response => $res });
is $res->code, 404;

Modoi->context->fetcher->cache->set($uri => Storable::freeze({ Content => 'CONTENT', ContentType => 'text/html' }));

$plugin->filter_response(Modoi->context, { response => $res });
is $res->code, 200;
is $res->content, 'CONTENT';
is $res->content_type, 'text/html';

Modoi->context->fetcher->cache->set($uri => Storable::freeze({ Content => 'CONTENT', ContentType => 'text/html' }));

{
    $module->new->filter_request(Modoi->context, { request => GET($uri), response_ref => \my $res });
    ok not defined $res;
}

{
    $module->new(config => { content_type => 'text/*' })->filter_request(Modoi->context, { request => GET($uri), response_ref => \my $res });
    ok $res;
}
