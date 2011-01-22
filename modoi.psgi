#!perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";

use Modoi::Request;
use Modoi::Proxy;

our $proxy = Modoi::Proxy->new;

my $app = sub {
    my $env = shift;
    my $req = Modoi::Request->new($env);
    my $res = $proxy->serve($req);
    $res->finalize;
};
