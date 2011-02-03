use t::TestModoi;
use Plack::Test;
use HTTP::Request::Common;

eval { require Search::Estraier } or plan skip_all => 'Search::Estraier not installed';

plan tests => 5;

my $context = Modoi->context;
my $app = sub {
    my $res = $context->internal->serve($_[0]);
    return ref $res eq 'ARRAY' ? $res : $res->finalize;
};

test_psgi(
    app => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET '/search');
        is $res->code, 302, 'route /search not defined';
    },
);

my $component = $context->install_component('IndexEstraier');
isa_ok $component, 'Modoi::Component::IndexEstraier';

test_psgi(
    app => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET '/search?q=thisquery');
        is $res->code, 200, 'route /search defined';
        like $res->content, qr/<form/;
        like $res->content, qr/thisquery/;
    },
);
