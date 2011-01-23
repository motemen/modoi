package Plack::Middleware::ProxyAuth::Basic;
use strict;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(realm authenticator);
use Scalar::Util qw(blessed);
use MIME::Base64;

sub prepare_app {
    my $self = shift;

    my $auth = $self->authenticator or die 'authenticator is not set';
    if (blessed $auth && $auth->can('authenticate')) {
        $self->authenticator(sub { $auth->authenticate(@_) });
    } elsif (ref $auth ne 'CODE') {
        die 'authenticator should be a code reference or an object that responds to authenticate()';
    }
}

sub call {
    my ($self, $env) = @_;

    return $self->app->($env)
        unless $env->{REQUEST_URI} =~ m<^https?://>;

    my $auth = $env->{HTTP_PROXY_AUTHORIZATION}
        or return $self->unauthorized;

    if ($auth =~ /^Basic (.*)$/) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":");
        $pass = '' unless defined $pass;
        if ($self->authenticator->($user, $pass)) {
            $env->{REMOTE_USER} = $user;
            return $self->app->($env);
        }
    }

    return $self->unauthorized;
}

sub unauthorized {
    my $self = shift;
    my $body = 'Proxy authentication required';
    return [
        407,
        [ 'Content-Type' => 'text/plain',
          'Content-Length' => length $body,
          'Proxy-Authenticate' => 'Basic realm="' . ($self->realm || "restricted area") . '"' ],
        [ $body ],
    ];
}

1;
