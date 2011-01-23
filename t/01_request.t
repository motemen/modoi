use strict;
use Test::More tests => 3;

use_ok 'Modoi::Request';

my $env = {
    'psgi.url_scheme' => 'http',
    REQUEST_METHOD    => 'GET',
    SERVER_PROTOCOL   => 'HTTP/1.1',
    HTTP_HOST         => 'localhost',
    SERVER_NAME       => 'localhost',
    SCRIPT_NAME       => '/foo',
    SERVER_PORT       => '8080',
};

my $req = new_ok 'Modoi::Request', [ $env ];
my $http_req = $req->as_http_message;
isa_ok $http_req, 'HTTP::Request';
