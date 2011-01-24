use strict;
use lib 'modules/WWW-Futaba-Parser/lib';
use Test::More tests => 3;
use Modoi::Request;
use HTTP::Response;
use Path::Class;

use_ok 'Modoi::Component::FindMedia';

my $component = Modoi->install_component('FindMedia');
isa_ok $component, 'Modoi::Component::FindMedia', 'installed component';

# XXX modules/ 以下のファイルを使うよ！
my $content = file(qw(modules WWW-Futaba-Parser t samples img.2chan.net-b-res-106391645.htm))->slurp;
my $http_res = HTTP::Response->new(200, 'OK', [ Content_Type => 'text/html; charset=cp932' ], $content);
my $res = Modoi::Request->new_response_from_http_response($http_res); # FIXME ださいぞ

my @media = $component->find_media($res, 'http://img.2cha.net/b/res/106391645.htm');
is_deeply \@media, [
    URI->new('http://mar.2chan.net/img/b/src/1295728358066.jpg'),
], 'extracted @media';
