package Modoi::Fetcher;
use Mouse;
use LWP::UserAgent;

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
);

sub request {
    my ($self, $req) = @_;
    my $http_req = $req->as_http_message;
    my $http_res = $self->ua->request($http_req);
    return $req->new_response($http_res->code, $http_res->headers, $http_res->content);
}

1;
