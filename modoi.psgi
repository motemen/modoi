#!perl
use strict;
use warnings;
use lib 'lib', glob 'modules/*/lib';

use Modoi;
use Coro;
use Plack::Builder;

$SIG{TERM} = sub {
    Modoi->log(notice => 'got SIGTERM, exiting');
    exit 0;
};
$SIG{INT} = sub {
    Modoi->log(notice => 'got SIGINT, exiting');
    exit 0;
};

Modoi->initialize;
Modoi->install_component('Cache');
Modoi->install_component('StoreDB');
Modoi->install_component('Watch');
Modoi->install_component('ExtendExpires');
Modoi->install_component('IndexEstraier');
Modoi->install_component('Prefetch');

my $app = sub {
    my $env = shift;

    return sub {
        my $respond = shift;

        async {
            my $res;
            if ($env->{REQUEST_URI} =~ m(^/)) {
                $res = Modoi->internal->serve($env);
            } else {
                $res = Modoi->proxy->serve($env);
            }
            $respond->(ref $res eq 'ARRAY' ? $res : $res->finalize);
        };
    };
};

builder {
    if (my $auth = $ENV{MODOI_AUTH}) {
        enable 'ProxyAuth::Basic',
            authenticator => sub { join(':', @_[0,1]) eq $auth };
        enable_if { not $_[0]{REMOTE_USER} } 'Auth::Basic',
            authenticator => sub { join(':', @_[0,1]) eq $auth };
    }
    $app;
};
