package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Extractor;

use Coro;
use Coro::AnyEvent;

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
    isa => 'LWP::UserAgent',
    default => sub {
        LWP::UserAgent::AnyEvent::Coro->new;
    },
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

    Modoi->log(debug => "fetch $uri");

    my $cv = delete $args{Condvar};

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

    my $cv = AnyEvent->condvar;

    $self->fetch_async(
        $req->uri,
        ETag         => scalar $req->header('If-None-Match'),
        LastModified => scalar $req->header('If-Modified-Since'),
        Condvar      => $cv,
    );

    my $fetch_res = $cv->recv;
    $self->do_prefetch($fetch_res->http_response);

    my $res = $fetch_res->http_response;
    if (!$fetch_res->is_error && _should_serve_content($req)) {
        $res->code(200);
        $res->content($fetch_res->content);
        $res->header(Content_Type => $fetch_res->content_type);
        $res->remove_header('Content-Encoding'); # XXX
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

package LWP::UserAgent::AnyEvent::Coro;
use base 'LWP::UserAgent';

use AnyEvent;
use AnyEvent::HTTP;
use Coro;
use Coro::AnyEvent;

$AnyEvent::HTTP::MAX_PER_HOST = 16; # :->

sub send_request {
    my ($self, $request, $arg, $size) = @_;

    http_request $request->method, $request->uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0, Coro::rouse_cb;

    my ($data, $header) = Coro::rouse_wait;

    my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
    $response->request($request);
    $response;
}

1;
