use strict;
use warnings;
use Test::More tests => 10;
use FindBin;

use_ok 'Modoi';

my $modoi = Modoi->new(
    config => {
        plugin_path => "$FindBin::Bin/../lib/Modoi/Plugin",
        plugins => [
            { module => 'ServeCache' },
            { module => 'Fetcher::Script' },
        ],
    }
);

isa_ok $modoi, 'Modoi';

isa_ok $modoi->$_, 'Modoi::' . ucfirst foreach @Modoi::Components;

isa_ok [$modoi->plugins('Fetcher::Script')]->[0], 'Modoi::Plugin::Fetcher::Script';
isa_ok [$modoi->plugins(qr/Fetcher/)]->[0], 'Modoi::Plugin::Fetcher::Script';
isa_ok [$modoi->plugins(sub { /e$/ })]->[0], 'Modoi::Plugin::ServeCache';
