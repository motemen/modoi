use strict;
use utf8;
use Test::More tests => 4;
use t::TestModoi;

BEGIN { use_ok 'Modoi::Proxy' }

my $proxy = Modoi::Proxy->new;

my $res = fake_http GET => 'http://img.2chan.net/b/res/69762910.htm';

$proxy->rewrite_links($res, sub { "PROXY?$_[0]" });

my @uri = $res->decoded_content =~ /href="(.+?)"/g;
ng scalar grep { m'^PROXY:javascript:' }              @uri;
ng scalar grep { m'^PROXY:http://www.amazon.co.jp/' } @uri;
ng scalar grep { m'^http://img.2chan.net' }           @uri;
