package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Extractor;

use Coro;
use Coro::AnyEvent;

use HTTP::Status;
use URI::Fetch;
use UNIVERSAL::require;

has 'cache', (
    is  => 'rw',
    isa => 'Cache::Cache',
    default => sub {
        Cache::MemoryCache->require or die $@;
        Cache::MemoryCache->new;
    },
);

has 'ua', (
    is  => 'rw',
    isa => 'LWP::UserAgent::AnyEvent::Coro',
    default => sub { LWP::UserAgent::AnyEvent::Coro->new(timeout => 10) },
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub fetch_async {
    my ($self, $uri, %args) = @_;

    my $cv = delete $args{CondVar};

    async {
        my $res = URI::Fetch->fetch(
            "$uri",
            ForceResponse => 1,
            UserAgent     => $self->ua,
            Cache         => $self->cache,
            %args,
        );
        Modoi->log(debug => "$uri -> " . $res->http_status);
        $cv->send($res) if $cv;
    };
}

sub fetch {
    my ($self, $req) = @_;

    Modoi->log(debug => 'fetch ' . $req->uri);

#   my $cv = AnyEvent->condvar;
#
#   $self->fetch_async(
#       $req->uri,
#       ETag         => scalar $req->header('If-None-Match'),
#       LastModified => scalar $req->header('If-Modified-Since'),
#       CondVar      => $cv,
#   );
#
#   my $fetch_res = $cv->recv;

    # XXX なんか fetch_async() 中にここで AnyEvent 通すと固まる
    my $fetch_res = URI::Fetch->fetch(
        $req->uri,
        ForceResponse => 1,
        Cache         => $self->cache,
        ETag          => scalar $req->header('If-None-Match'),
        LastModified  => scalar $req->header('If-Modified-Since'),
    );

    my $res = $fetch_res->http_response;
    $res->content($fetch_res->content);
    $res->remove_header('Content-Encoding');

    Modoi->log(debug => $req->uri . " -> " . $fetch_res->http_status);

    $self->do_prefetch($res);

    if (!$fetch_res->is_error && _should_serve_content($req)) {
        $res->code(RC_OK);
        $res->header(Content_Type => $fetch_res->content_type);
    }
    $res;
}

sub do_prefetch {
    my ($self, $res) = @_;

    return unless $res->content_type =~ m'^text/';

    my $result = $self->extractor->extract($res);
    foreach (@{$result->{images}}) {
        Modoi->log(debug => "prefetch $_");
        $self->fetch_async($_);
    }
}

sub _should_serve_content {
    my ($req) = @_;

    ($req->header('Pragma')        || '') eq 'no-cache' ||
    ($req->header('Cache-Control') || '') eq 'no-cache' ||
    !$req->header('If-Modified-Since');
}

sub logger_name {
    __PACKAGE__ . " [$LWP::UserAgent::AnyEvent::Coro::Count]";
}

package LWP::UserAgent::AnyEvent;
use base 'LWP::UserAgent';

use AnyEvent;
use AnyEvent::HTTP;

sub send_request {
    my ($self, $request, $arg, $size) = @_;

    my $cv = AnyEvent->condvar;
    http_request $request->method, $request->uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0, sub { $cv->send(@_) };

    my ($data, $header) = $cv->recv;

    my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
    $response->request($request);
    $response;
}

package LWP::UserAgent::AnyEvent::Coro;
use base 'LWP::UserAgent';

use AnyEvent;
use AnyEvent::HTTP;
use Coro;
use Coro::AnyEvent;

our $Count = 0;

sub send_request {
    my ($self, $request, $arg, $size) = @_;

    $Count++;
    http_request $request->method, $request->uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0, Coro::rouse_cb;

    my ($data, $header) = Coro::rouse_wait;
    $Count--;

    my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
    $response->request($request);
    $response;
}

1;
