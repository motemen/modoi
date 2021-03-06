use t::TestModoi;
use Plack::Builder;
use Plack::Loader;
use Test::TCP '1.00';
use LWP::UserAgent;

plan tests => 3;

local $ENV{MODOI_AUTH} = 'user:pass';
my $app = do 'modoi.psgi';
die $@ if $@;

# XXX Plack::Test does not support proxy test

my $ua = LWP::UserAgent->new;

my $external_server = Test::TCP->new(
    code => sub {
        Plack::Loader->auto(port => $_[0], host => '127.0.0.1')->run(sub { [ 200, [], [] ] });
    },
);
my $external_port = $external_server->port;
my $res = $ua->get("http://127.0.0.1:$external_port/");
is $res->code, 200, 'precondition: external server without proxy';

test_tcp(
    server => sub {
        Modoi->fetcher->ua(LWP::UserAgent->new); # replace paranoid agent
        Plack::Loader->auto(port => $_[0], host => '127.0.0.1')->run($app);
    },
    client => sub {
        my $port = shift;

        subtest internal => sub {
            my $res = $ua->get("http://127.0.0.1:$port/");
            is $res->code, 401, 'internal without auth';

            my $res = $ua->get("http://127.0.0.1:$port/", Authorization => 'Basic dXNlcjpwYXNz');
            is $res->code, 200, 'internal with auth';
        };

        subtest proxy => sub {
            $ua->proxy(http => "http://127.0.0.1:$port/");

            my $res = $ua->get("http://127.0.0.1:$external_port/external");
            is $res->code, 407, 'proxy without auth';

            my $res = $ua->get("http://127.0.0.1:$external_port/external", Proxy_Authorization => 'Basic dXNlcjpwYXNz');
            is $res->code, 200, 'proxy with auth' or diag explain $res;
        };
    },
);

done_testing;
