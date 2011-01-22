#!perl
use strict;
use warnings;
use lib 'lib', glob 'modules/*/lib';

use Modoi;

Modoi->initialize;
Modoi->install_component('Cache');
Modoi->install_component('StoreDB');

my $app = sub {
    my $env = shift;
    Modoi->start_session(sub {
        my $res = Modoi->proxy->serve($env);
        $res->finalize;
    });
};
