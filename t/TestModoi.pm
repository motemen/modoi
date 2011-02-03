package t::TestModoi;
use strict;
use warnings;
use Test::More;
use Modoi;
use Carp;
use Exporter::Lite ();
use lib 'lib', glob 'modules/*/lib';

our @EXPORT = qw(
    test_proxy
    __make_fetcher_ua_internal__
);

sub import {
    strict->import;

    # not to break running application
    Modoi->config->config_file('t/config.yaml');

    my $pkg = caller;
    eval qq{
        package $pkg;
        use Test::More;
    };
    die $@ if $@;

    goto \&Exporter::Lite::import;
}

sub test_proxy {
    require Test::TCP;
    require Plack::Loader;
    require HTTP::Message::PSGI;
    require Modoi;

    my %args = @_;
    my $external_app = delete $args{external_app} or croak 'external_app required';
    my $external_server = Test::TCP->new(
        code => sub {
            Plack::Loader->auto(port => $_[0], host => '127.0.0.1')->run($external_app);
        },
    );
    my $external_port = $external_server->port;

    my $proxy_app = delete $args{proxy_app};
    my $client    = delete $args{client};
    $client->(
        sub {
            my $req = shift;
            my $env = $req->to_psgi;
            $env->{REQUEST_URI} = do {
                my $uri = URI->new($env->{REQUEST_URI});
                $uri->scheme('http');
                $uri->host('127.0.0.1');
                $uri->port($external_port);
                "$uri";
            };
            $proxy_app->($env);
        }
    );
}

sub __make_fetcher_ua_internal__ {
    require Modoi::Fetcher;
    eval q{
        package t::Modoi::Fetcher::Role::Internal;
        use Mouse::Role;

        has '+ua' => (
            default => sub {
                require LWPx::ParanoidAgent;
                my $ua = LWPx::ParanoidAgent->new;
                $ua->whitelisted_hosts('127.0.0.1');
                $ua->blocked_hosts(qr//);
                return $ua;
            }
        );
    };
    die $@ if $@;
    t::Modoi::Fetcher::Role::Internal->meta->apply(Modoi::Fetcher->meta);
}

1;
