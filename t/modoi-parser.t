use strict;
use utf8;
use Test::More tests => 18;
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
    is $result->{summary}, '荒れ狂ういもげにベッカーズのハンバーガーが降臨 ';
    is "$result->{body}\n", <<__BODY__;
荒れ狂ういもげにベッカーズのハンバーガーが降臨 
ﾅﾆｺﾚ 
Ｇ 
ガッツのGか 
ご注文後に焼き上げるとか当たり前のこと言われても… 
ベッカーズはＪＲ東日本系列だから関東にしかないよ 
値段が高いちょっとあらびき過ぎる 
安いと思った俺は 
ベッカーズのパンズは店で焼いてるからえらく美味しいあれだけで食う価値はある 
>ベッカーズのパンズは店で焼いてるからえらく美味しい>あれだけで食う価値はあるホントかよ　スゲー店があったもんだな 
__BODY__
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
    is $result->{summary}, 'あさのにじうらはすみきったそらのようにキレイなのよー ';
}

{
    my $res = HTTP::Response->new(200);
       $res->content(scalar file("$FindBin::Bin/samples/jun.2chan.net-b-res-9751015.htm")->slurp);
       $res->content_type('text/html; charset=Shift_JIS');
       $res->request(GET 'http://jun.2chan.net/b/res/9751015.htm');

    my $result = $parser->parse_response($res);
    isa_ok $result, 'HASH';
    isa_ok $result->{datetime}, 'DateTime';
    is $result->{datetime}, '2009-01-25T06:04:13';
    is $result->{summary}, 'ｷﾀ━━━━━━(ﾟ∀ﾟ)━━━━━━ !!!!! ';
}

{
    my $res = HTTP::Response->new(200);
       $res->content(scalar file("$FindBin::Bin/samples/zip.4chan.org-a-res-18369055.html")->slurp);
       $res->content_type('text/html');
       $res->request(GET 'http://zip.4chan.org/a/res/18369055.html');

    my $result = $parser->parse_response($res);
    isa_ok $result, 'HASH';
    isa_ok $result->{datetime}, 'DateTime';
    is $result->{datetime}, '2009-01-27T05:07:00';
    is $result->{summary}, 'soysource';
}
