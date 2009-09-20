package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Extractor;

use Coro;
use Coro::AnyEvent;

use List::MoreUtils qw(uniq);
use HTTP::Status;
use HTTP::Request::Common qw(GET);
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

__PACKAGE__->meta->make_immutable;

no Any::Moose;

our %UriSemaphore;

# XXX returns Fetch::URI::Response
sub fetch_cache {
    my ($self, $uri) = @_;
    URI::Fetch->fetch("$uri", Cache => $self->cache, ForceResponse => 1, NoNetwork => 1);
}

sub fetch_uri {
    my ($self, $uri) = @_;
    $self->fetch(GET $uri);
}

# TODO ながい
sub fetch {
    my ($self, $req) = @_;

    my %fetch_args = (
        ETag          => scalar $req->header('If-None-Match'),
        LastModified  => scalar $req->header('If-Modified-Since'),
        Cache         => $self->cache,
        UserAgent     => $self->ua,
        ForceResponse => 1,
    );

    if ($fetch_args{Etags} || $fetch_args{LastModified}) {
        my $cache_res = $self->fetch_cache($req->uri);
        if ($cache_res && $cache_res->content_type =~ /^image\//) { # TODO
            Modoi->log(debug => 'return NOT MODIFIED for ' . $req->uri);
            return HTTP::Response->new(RC_NOT_MODIFIED);
        }
    }

    Modoi->log(debug => '>>> fetch ' . $req->uri);

    $UriSemaphore{$req->uri} ||= Coro::Semaphore->new;
    if ($UriSemaphore{$req->uri}->count == 0) {
        Modoi->log(debug => $req->uri . ': currently fetching');
        $fetch_args{NoNetwork} = 1;
    }

    $UriSemaphore{$req->uri}->down;

    my $fetch_res = URI::Fetch->fetch($req->uri, %fetch_args);

    $UriSemaphore{$req->uri}->up;

    Modoi->log(debug => '<<< ' . $req->uri . ' (' . ($fetch_res ? $fetch_res->http_status || 'cache' : 404) . ')');

    my $http_status = $fetch_res->http_status || RC_OK;

    if ($http_status == RC_NOT_FOUND) {
        # serve cache
        Modoi->log(info => 'serving cache for ' . $req->uri);
        $fetch_res = $self->fetch_cache($req->uri) || $fetch_res;
    }

    my $res = $fetch_res->http_response || do {
        my $res = HTTP::Response->new($http_status);
        $res->header(
            ETag          => $fetch_res->etag,
            Last_Modified => $fetch_res->last_modified,
            Content_Type  => $fetch_res->content_type,
        );
        $res;
    };
    $res->request($req) unless $res->request;
    $res->content($fetch_res->content);
    $res->remove_header('Content-Encoding');
    $res->remove_header('Transfer-Encoding');

    if (!$fetch_res->is_error && _should_serve_content($req)) {
        $res->code(RC_OK);
        $res->header(Content_Type => $fetch_res->content_type);
    }

    $res;
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

sub _agent { $AnyEvent::HTTP::USERAGENT }

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
