use strict;
use Test::More tests => 5;
use HTTP::Response;
use HTTP::Request::Common;
use Storable;
use Cache::Memory;
use Modoi;

my $module = 'Modoi::Plugin::Filter::Response::ServeCacheOn404';

use_ok $module;

use FindBin;
Modoi->new;
Modoi->context->fetcher->cache(Cache::Memory->new);

my $plugin = $module->new;

my $uri = 'http://www.example.com/';
my $res = HTTP::Response->new(404);
$res->request(GET $uri);
$plugin->filter($res);
is $res->code, 404;

Modoi->context->fetcher->cache->set($uri => Storable::freeze({ Content => 'CONTENT', ContentType => 'text/html' }));

$plugin->filter($res);
is $res->code, 200;
is $res->content, 'CONTENT';
is $res->content_type, 'text/html';
