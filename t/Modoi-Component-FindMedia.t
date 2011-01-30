use strict;
use lib 'modules/WWW-Futaba-Parser/lib';
use t::TestModoi;
use Modoi::Request;
use HTTP::Response;
use Path::Class;

plan tests => 4;

use_ok 'Modoi::Component::FindMedia';

{
    package Modoi::Component::FindMedia;
    Modoi->config->package_config->{rules} = [
        { regexp => qr/(fu\d+\.\w+)\b/, rewrite => 'http://dec.2chan.net/up2/src/$1' },
        { regexp => qr/(f\d+\.\w+)\b/,  rewrite => 'http://dec.2chan.net/up/src/$1'  },
        { regexp => qr/(ss\d+\.\w+)\b/, rewrite => 'http://localhost/path/to/$1'     },
    ];
}

my $component = Modoi->install_component('FindMedia');
isa_ok $component, 'Modoi::Component::FindMedia', 'installed component';

subtest image => sub {
    # XXX modules/ 以下のファイルを使うよ！
    my $content = file(qw(modules WWW-Futaba-Parser t samples img.2chan.net-b-res-106391645.htm))->slurp;
    my $http_res = HTTP::Response->new(200, 'OK', [ Content_Type => 'text/html; charset=cp932' ], $content);
    my $res = Modoi::Request->new_response_from_http_response($http_res); # FIXME ださいぞ

    my @media = $component->find_media($res, 'http://img.2chan.net/b/res/106391645.htm');
    is_deeply \@media, [
        URI->new('http://mar.2chan.net/img/b/src/1295728358066.jpg'),
    ], 'extracted @media';
};

subtest ss => sub {
    my $content = file(qw(modules WWW-Futaba-Parser t samples dat.2chan.net-b-res-62973238.htm))->slurp;
    my $http_res = HTTP::Response->new(200, 'OK', [ Content_Type => 'text/html; charset=cp932' ], $content);
    my $res = Modoi::Request->new_response_from_http_response($http_res);

    my @media = $component->find_media($res, 'http://dat.2chan.net/b/res/62973238.htm');
    is_deeply \@media, [
        URI->new('http://jul.2chan.net/dat/b/src/1295827200356.gif'),
        URI->new('http://localhost/path/to/ss131992.mp3'),
    ], 'extracted @media';
};
