use strict;
use warnings;
use Test::More tests => 8;
use FindBin;
use Modoi;

my $modoi = Modoi->new(
    config => {
        plugin_path => "$FindBin::Bin/../lib/Modoi/Plugin",
        plugins => [
            { module => 'Filter::Response::ServeCacheOn404' },
            { module => 'Filter::Fetcher::Script' },
        ],
    }
);

isa_ok $modoi, 'Modoi';

isa_ok $modoi->$_, 'Modoi::' . ucfirst foreach @Modoi::Components;

isa_ok [$modoi->plugins('Fetcher')]->[0], 'Modoi::Plugin::Filter::Fetcher::Script';
isa_ok [$modoi->plugins(qr/Fetcher/)]->[0], 'Modoi::Plugin::Filter::Fetcher::Script';
isa_ok [$modoi->plugins(sub { /Response/ })]->[0], 'Modoi::Plugin::Filter::Response::ServeCacheOn404';