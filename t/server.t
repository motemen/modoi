use t::Modoi;
use Plack::Test;
use HTTP::Request::Common;

use Modoi::Config {
    logger => { dispatchers => [ 'screen' ], screen => { min_level => 'debug' } }
};

use Modoi::Server;

$Plack::Test::Impl = 'Server';
$ENV{PLACK_SERVER} = 'AnyEvent::HTTPD';

my $server = Modoi::Server->new;
my $app = $server->as_psgi_app;

$Test::Builder::Level = $Test::Builder::Level + 3;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/status');
    is $res->code, 200, '/status' or diag $res->content;
};

done_testing;
