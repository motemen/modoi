use strict;
use Test::More tests => 4;
use HTTP::Response;
use HTTP::Request::Common;
use Modoi;

my $module = 'Modoi::Plugin::Request::BasicAuth';

use_ok $module;

use FindBin;
Modoi->new;

my $plugin = $module->new(config => { username => 'username', password => 'password' });

{
    $plugin->filter_request(
        Modoi->context, {
            request => GET('http://img.2chan.net/b/'),
            response_ref => \my $res,
        }
    );
    is $res->code, 401;
    like $res->header('WWW-Authenticate'), qr/^Basic /;
}

{
    $plugin->filter_request(
        Modoi->context, {
            request => GET('http://img.2chan.net/b/', Authorization => 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='),
            response_ref => \my $res,
        }
    );
    ok not defined $res;
}
