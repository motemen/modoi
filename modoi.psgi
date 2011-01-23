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

    my $res;
    if ($env->{REQUEST_URI} =~ m(^/)) {
        $res = Modoi->internal->serve($env);
    } else {
        $res = Modoi->proxy->serve($env);
    }
    return ref $res eq 'ARRAY' ? $res : $res->finalize;
};

sub {
    my $env = shift;
    return Modoi->start_session(sub { $app->($env) });
};
