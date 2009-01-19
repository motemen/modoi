use strict;
use Test::More tests => 4;
use HTTP::Response;
use HTTP::Request::Common;
use Modoi;

my $module = 'Modoi::Plugin::Filter::Request::BasicAuth';

use_ok $module;

use FindBin;
Modoi->new;

my $plugin = $module->new(config => { username => 'username', password => 'password' });

{
    $plugin->filter(GET('http://img.2chan.net/b/'), \my $res);
    is $res->code, 401;
    like $res->header('WWW-Authenticate'), qr/^Basic /;
}

{
    $plugin->filter(GET('http://img.2chan.net/b/', Authorization => 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='), \my $res);
    ok not defined $res;
}
