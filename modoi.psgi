#!perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";

use Modoi;
use Modoi::Request;

Modoi->initialize;

my $app = sub {
    my $env = shift;
    my $req = Modoi::Request->new($env);
    my $res = Modoi->proxy->serve($req);
    $res->finalize;
};
