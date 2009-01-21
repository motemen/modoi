use strict;
use warnings;
use Test::More tests => 7;
use HTTP::Response;
use FindBin;
use Path::Class qw(file);
use HTTP::Request::Common;

use_ok 'Modoi::Parser';

Modoi->new(config => { assets_path => "$FindBin::Bin/../assets" });

my $parser = Modoi::Parser->new;

{
    my $res = HTTP::Response->new(200);
       $res->content(scalar file("$FindBin::Bin/samples/img.2chan.net-b-res-52253644.htm")->slurp);
       $res->content_type('text/html; charset=Shift_JIS');
       $res->request(GET 'http://img.2chan.net/b/res/52253644.htm');

    my $result = $parser->parse_response($res);
    isa_ok $result, 'HASH';
    isa_ok $result->{datetime}, 'DateTime';
    is $result->{datetime}, '2009-01-24T21:03:43';
}

{
    my $res = HTTP::Response->new(200);
       $res->content(scalar file("$FindBin::Bin/samples/img.2chan.net-b-res-52288458.htm")->slurp);
       $res->content_type('text/html; charset=Shift_JIS');
       $res->request(GET 'http://img.2chan.net/b/res/52288458.htm');

    my $result = $parser->parse_response($res);
    isa_ok $result, 'HASH';
    isa_ok $result->{datetime}, 'DateTime';
    is $result->{datetime}, '2009-01-25T05:31:10';
}
