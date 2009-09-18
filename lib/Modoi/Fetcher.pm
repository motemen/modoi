package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Extractor;

use Coro;
use Coro::AnyEvent;

use List::MoreUtils qw(uniq);
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
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent::AnyEvent::Coro->new },
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

our %UriSemaphore;

sub fetch_uri {
    my ($self, $uri, %args) = @_;

    Modoi->log(debug => '>>> fetch ' . $uri);

    my %fetch_args = (
        ForceResponse => 1,
        Cache         => $self->cache,
        UserAgent     => $self->ua,
        %args,
    );

    $UriSemaphore{$uri} ||= Coro::Semaphore->new;
    if ($UriSemaphore{$uri}->count == 0) {
        Modoi->log(debug => "$uri: currently fetching") if $UriSemaphore{$uri}->count == 0;
        $fetch_args{NoNetwork} = 1;
    }

    $UriSemaphore{$uri}->down;

    my $res = URI::Fetch->fetch("$uri", %fetch_args);

    $UriSemaphore{$uri}->up;

    Modoi->log(debug => "<<< $uri (" . ($res->http_status || 'cache') . ')');

    $res;
}

sub fetch {
    my ($self, $req) = @_;

    my $fetch_res = $self->fetch_uri(
        $req->uri,
        ETag         => scalar $req->header('If-None-Match'),
        LastModified => scalar $req->header('If-Modified-Since'),
    );

    my $res = $fetch_res->http_response || do {
        my $res = HTTP::Response->new($fetch_res->http_status || RC_OK);
        $res->header(ETag => $fetch_res->etag);
        $res->header(Last_Modified => $fetch_res->last_modified);
        $res->header(Content_Type => $fetch_res->content_type);
        $res;
    };
    $res->request($req) unless $res->request;
    $res->content($fetch_res->content);
    $res->remove_header('Content-Encoding');
    $res->remove_header('Transfer-Encoding');

    $self->do_prefetch($res);

    if (!$fetch_res->is_error && _should_serve_content($req)) {
        $res->code(RC_OK);
        $res->header(Content_Type => $fetch_res->content_type);
    }
    $res;
}

sub do_prefetch {
    my ($self, $res) = @_;

    return unless $res->is_success;
    return unless $res->content_type =~ m'^text/';

    foreach my $uri ($self->extractor->extract($res)) {
        Modoi->log(debug => "prefetch $uri");
        async { $self->fetch_uri($uri) };
    }
}

sub _should_serve_content {
    my ($req) = @_;

    ($req->header('Pragma')        || '') eq 'no-cache' ||
    ($req->header('Cache-Control') || '') eq 'no-cache' ||
    !$req->header('If-Modified-Since');
}

sub logger_name {
    sprintf '%s [%d]', __PACKAGE__, (scalar grep { $_->count == 0 } values %UriSemaphore);
}

package LWP::UserAgent::AnyEvent::Coro;
use base 'LWP::UserAgent';

use AnyEvent;
use AnyEvent::HTTP;
use Coro;
use Time::HiRes;

sub send_request {
    my ($self, $request, $arg, $size) = @_;

    my $t = [ Time::HiRes::gettimeofday ];

    http_request $request->method, $request->uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0, Coro::rouse_cb;

    my ($data, $header) = Coro::rouse_wait;

    my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
    $response->request($request);

    Modoi->log(debug => sprintf '%s %.2fs', $request->uri, Time::HiRes::tv_interval $t);

    $response;
}

1;
