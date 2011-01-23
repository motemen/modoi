package Modoi::Fetcher;
use Mouse;
use Modoi;
use LWP::UserAgent;

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
);

# TODO $fetcher->on_response($res, $req)
sub request {
    my ($self, $req) = @_;

    my $http_res = $self->ua->simple_request($req->as_http_message);
    my $res = $req->new_response_from_http_response($http_res);

    $self->modify_response($res, $req);
    Modoi->log(info => $req->method, $req->request_uri, '=>', $res->code);

    return $res;
}

sub modify_response {
    my ($self, $res, $req) = @_;
    # hook this
}

1;
