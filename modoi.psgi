#!perl
use strict;
use warnings;
use lib 'lib', glob 'modules/*/lib';

use Modoi;
use Coro;
use Data::Dumper;
use Plack::Builder;

$SIG{TERM} = sub {
    Modoi->log(notice => 'got SIGTERM, exiting');
    Modoi->store_state;
    exit 0;
};

$SIG{INT} = sub {
    Modoi->log(notice => 'got SIGINT, exiting');
    Modoi->store_state;
    exit 0;
};

END {
    Modoi->store_state;
}

Modoi->initialize;

# XXX not to cause error in xslate
foreach (keys %{ Modoi->context->installed_components }) {
    Modoi->log(debug => "$_ status:", Data::Dumper->new([ Modoi->component($_)->status ])->Indent(0)->Terse(1)->Dump);
}

my $app = sub {
    my $env = shift;

    $env->{'psgi.streaming'} or die 'modoi requires psgi.streaming feature!';
    $env->{'psgi.nonblocking'} or die 'modoi requires psgi.nonblocking feature!';

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
    enable_if { $_[0]{REQUEST_URI} =~ m(^/) } 'Static',
        root => './root/', path => qr<^/(images|css)/>;
    $app;
};
