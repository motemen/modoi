#!perl
use strict;
use warnings;
use lib 'lib', glob 'modules/*/lib';

use Modoi;
use Plack::Builder;

Modoi->initialize;
Modoi->install_component('Cache');
Modoi->install_component('StoreDB');
Modoi->install_component('Watch');

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

builder {
    if (my $auth = $ENV{MODOI_AUTH}) {
        enable 'ProxyAuth::Basic',
            authenticator => sub { join(':', @_[0,1]) eq $auth };
        enable_if { not $_[0]{REMOTE_USER} } 'Auth::Basic',
            authenticator => sub { join(':', @_[0,1]) eq $auth };
    }
    sub {
        my $env = shift;
        return Modoi->start_session(sub { $app->($env) });
    };
};
