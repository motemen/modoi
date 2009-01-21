use strict;
use Test::More tests => 3;
use HTTP::Response;
use HTTP::Request::Common;
use Modoi;

my $module = 'Modoi::Plugin::Filter::Request::ServeCache';

use_ok $module;

use FindBin;
Modoi->new;

my $plugin = $module->new(config => { content_type => 'image/*' });

my $uri = 'http://www.example.com/';
my $image_uri = 'http://www.example.com/logo.png';

Modoi->context->fetcher->cache->set($uri => Storable::freeze({ Content => 'CONTENT', ContentType => 'text/html' }));
Modoi->context->fetcher->cache->set($image_uri => Storable::freeze({ Content => 'CONTENT', ContentType => 'image/png' }));

{
    $plugin->filter_request(Modoi->context, { request => GET($uri), response_ref => \my $res });
    ok not defined $res;
}

{
    $plugin->filter_request(Modoi->context, { request => GET($image_uri), response_ref => \my $res });
    ok $res;
}
