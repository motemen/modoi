use t::Modoi;

plan tests => 5;

use_ok 'Modoi::Proxy';

my $proxy = new_ok 'Modoi::Proxy';

my $res = fake_http GET => 'http://img.2chan.net/b/res/69762910.htm';

$proxy->rewrite_links($res, sub { "PROXY?$_[0]" });

my @uri = $res->decoded_content =~ /href="(.+?)"/g;
ng scalar grep { m'^PROXY:javascript:' }              @uri;
ng scalar grep { m'^PROXY:http://www.amazon.co.jp/' } @uri;
ng scalar grep { m'^http://img.2chan.net' }           @uri;

done_testing;
