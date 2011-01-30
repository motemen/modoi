package Modoi::Proxy;
use Mouse;
use Modoi::Fetcher;
use Modoi::Request;
use Plack::App::Proxy;
use HTTP::Headers;

has fetcher => (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    default => sub { Modoi::Fetcher->new },
);

has proxy_app => (
    is  => 'rw',
    isa => 'Plack::App::Proxy',
    default => sub { Plack::App::Proxy->new },
);

sub prepare_request {
    my ($self, $env) = @_;

    my $original_req = Modoi::Request->new($env);

    my $url     = $self->proxy_app->build_url_from_env($env);
    my $headers = $self->proxy_app->build_headers_from_env($env, $original_req);

    my $req = Modoi::Request->new($env);
    $req->{headers} = HTTP::Headers->new(%$headers);

    return $req;
}

# PSGI env -> Modoi::Response
sub serve {
    my ($self, $env) = @_;
    my $req = $self->prepare_request($env);
    Modoi->log(debug => 'serve ' . $req->request_uri);
    return $self->fetcher->request($req);
}

1;
