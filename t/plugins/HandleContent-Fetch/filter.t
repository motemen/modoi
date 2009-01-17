use strict;
use Test::More tests => 2;
use HTTP::Response;
use HTTP::Request::Common;
use Modoi;

my $module = 'Modoi::Plugin::HandleContent::Fetch';

use_ok $module;

use FindBin;
Modoi->new(config => { assets_path => "$FindBin::Bin/../../../assets" });

my $res = HTTP::Response->new(200);
$res->content('...  http://img.2chan.net/b/src/1232206461456.gif ...');
$res->request(GET 'http://img.2chan.net/b/');

my @links = $module->new->find_links($res);

is_deeply \@links, ['http://img.2chan.net/b/src/1232206461456.gif'];
