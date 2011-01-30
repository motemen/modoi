package Modoi::Fetcher;
use Mouse;
use Modoi;
use Modoi::Request;
use LWPx::ParanoidAgent;
use Coro;
use Coro::LWP; # TODO timeout の実装
use Coro::Semaphore;
use AnyEvent;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use URI;

our $MaxRequestPerHost = 4;
our %Semaphore;

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWPx::ParanoidAgent->new },
);

has timeout => (
    is  => 'rw',
    isa => 'Int',
    default => 180,
);

# Modoi::Request -> Modoi::Response
sub request {
    my ($self, $req) = @_;

    my $host = URI->new($req->request_uri)->host;
    my $sem = $Semaphore{$host} ||= Coro::Semaphore->new($MaxRequestPerHost);
    Modoi->log(debug => "semaphore[$host] =", $sem->count);
    Modoi->log(notice => 'MaxRequestPerHost exceeded, blocking:', $req->request_uri) if $sem->count <= 0;
    my $guard = $sem->guard;

    my $http_res = HTTP::Response->new(500, 'read timeout', [ 'Content-Type' => 'text/plain' ]);
    my $coro = async { $http_res = $self->ua->simple_request($req->as_http_message) };
    my $w = AE::timer $self->timeout, 0, sub {
        Modoi->log(warn => 'timeout:', $req->method, $req->request_uri);
        $coro->cancel;
    };
    $coro->join;
    my $res = $req->new_response_from_http_response($http_res);

    $self->modify_response($res, $req);
    Modoi->log(info => $req->method, $req->request_uri, '=>', $res->code);

    return $res;
}

# url -> Modoi::Response
sub fetch {
    my ($self, $url) = @_;

    my $env = GET($url)->to_psgi;
    # HTTP::Message::PSGI does not support proxy request
    $env->{REQUEST_URI} = $url;

    my $req = Modoi::Request->new($env);
    return $self->request($req);
}

sub modify_response {
    my ($self, $res, $req) = @_;
    # hook this
}

1;
