#!perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";

use Modoi;

Modoi->initialize;
Modoi->install_component('Cache');

my $app = sub {
    my $env = shift;
    my $res = Modoi->proxy->serve($env);
    $res->finalize;
};
