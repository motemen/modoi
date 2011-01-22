package Modoi::Fetcher;
use Mouse;
use Modoi;
use LWP::UserAgent;

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
);

sub request {
    my ($self, $req) = @_;
    my $http_req = $req->as_http_message;
    my $http_res = $self->ua->simple_request($http_req);
    Modoi->log(info => $req->method, $req->request_uri, '=>', $http_res->status_line);
    return $req->new_response_from_http_response($http_res);
}

1;
