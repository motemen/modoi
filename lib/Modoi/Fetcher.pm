package Modoi::Fetcher;
use Mouse;
use Modoi;
use Modoi::Request;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Message::PSGI;

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
);

sub request {
    my ($self, $req) = @_;

    my $http_res = $self->ua->simple_request($req->as_http_message);
    my $res = $req->new_response_from_http_response($http_res);

    $self->modify_response($res, $req);
    Modoi->log(info => $req->method, $req->request_uri, '=>', $res->code);

    return $res;
}

sub fetch {
    my ($self, $url) = @_;

    my $env = GET($url)->to_psgi;
    $env->{REQUEST_URI} = $url;

    my $req = Modoi::Request->new($env);
    return $self->request($req);
}

sub modify_response {
    my ($self, $res, $req) = @_;
    # hook this
}

1;
