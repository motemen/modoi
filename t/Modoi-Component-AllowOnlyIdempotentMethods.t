use t::TestModoi;
use Modoi::Request;
use HTTP::Request::Common;

__make_fetcher_ua_internal__;

my $context = Modoi::Context->new;
my $component = $context->install_component('AllowOnlyIdempotentMethods');
isa_ok $component, 'Modoi::Component::AllowOnlyIdempotentMethods';

test_proxy(
    external_app => sub {
        [ 200, [], [] ]
    },
    proxy_app => sub {
        my $env = shift;
        $context->fetcher->request(Modoi::Request->new($env))->finalize;
    },
    client => sub {
        my $cb = shift;
        is $cb->(HEAD '/')->[0], 200, 'HEAD -> 200';
        is $cb->(GET  '/')->[0], 200, 'GET  -> 200';
        is $cb->(POST '/')->[0], 405, 'POST -> 405';
    },
);

done_testing;
