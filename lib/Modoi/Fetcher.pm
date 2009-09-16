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
    default => sub { LWP::UserAgent::AnyEvent::Coro->new },
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

our %Fetching;

sub fetch_async {
    my ($self, $uri, %args) = @_;

    my $cv = delete $args{CondVar};

    async {
        $Coro::current->desc($uri);

        my $res;
        if ($Fetching{$uri}) {
            Modoi->log(debug => "$uri: currently fetching");
            $Fetching{$uri}->wait;

            $res = URI::Fetch->fetch(
                "$uri",
                ForceResponse => 1,
                Cache         => $self->cache,
                NoNetwork     => 1,
                %args,
            );
            Modoi->log(debug => "<<< $uri (cache)");
        } else {
            $res = URI::Fetch->fetch(
                "$uri",
                ForceResponse => 1,
                UserAgent     => LWP::UserAgent::AnyEvent::Coro->new,
                Cache         => $self->cache,
                %args,
            );
            Modoi->log(debug => "<<< $uri (" . $res->http_status . ')');
        }
        $cv->send($res) if $cv;
    };
}

sub fetch_sync {
    my ($self, $uri, %args) = @_;

    my $res;
    if ($Fetching{$uri}) {
        Modoi->log(debug => "$uri: currently fetching");
        $Fetching{$uri}->wait;

        $res = URI::Fetch->fetch(
            "$uri",
            ForceResponse => 1,
            Cache         => $self->cache,
            NoNetwork     => 1,
            %args,
        );
        Modoi->log(debug => "<<< $uri (cache)");
    } else {
        $res = URI::Fetch->fetch(
            "$uri",
            ForceResponse => 1,
            Cache         => $self->cache,
            %args,
        );
        Modoi->log(debug => "<<< $uri (" . $res->http_status . ')');
    }
    $res;
}

sub fetch {
    my ($self, $req) = @_;

    Modoi->log(debug => '>>> fetch ' . $req->uri);

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
#   my $fetch_res = URI::Fetch->fetch(
#       $req->uri,
#       ForceResponse => 1,
#       Cache         => $self->cache,
#       ETag          => scalar $req->header('If-None-Match'),
#       LastModified  => scalar $req->header('If-Modified-Since'),
#   );
 
    my $fetch_res = $self->fetch_sync(
        $req->uri,
        ETag         => scalar $req->header('If-None-Match'),
        LastModified => scalar $req->header('If-Modified-Since'),
    );

    my $res = $fetch_res->http_response || do {
        my $res = HTTP::Response->new($fetch_res->http_status);
        $res->header(ETag => $fetch_res->etag);
        $res->header(Last_Modified => $fetch_res->last_modified);
        $res->header(Content_Type => $fetch_res->content_type);
        $res;
    };
    $res->content($fetch_res->content);
    $res->remove_header('Content-Encoding');
    $res->remove_header('Transfer-Encoding');

#   Modoi->log(debug => '<<< ' . $req->uri . ' (' . $fetch_res->http_status . ')');

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
    sprintf '%s [%d]', __PACKAGE__, scalar grep { $_->count == 0 } values %Fetching;
}

# package LWP::UserAgent::AnyEvent;
# use base 'LWP::UserAgent';
# 
# use AnyEvent;
# use AnyEvent::HTTP;
# use Coro::AnyEvent;
# 
# sub send_request {
#     my ($self, $request, $arg, $size) = @_;
# 
#     my $cv = AnyEvent->condvar;
# 
#     http_request $request->method, $request->uri,
#         timeout => $self->timeout, headers => $request->headers, recurse => 0, sub { $cv->send(@_) };
# 
#     my ($data, $header) = $cv->recv;
# 
#     my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
#     $response->request($request);
#     $response;
# }

package LWP::UserAgent::AnyEvent::Coro;
use base 'LWP::UserAgent';

use AnyEvent;
use AnyEvent::HTTP;
use Coro;
use Coro::AnyEvent;
use Coro::Semaphore;

# $AnyEvent::HTTP::MAX_PER_HOST = 1;

sub send_request {
    my ($self, $request, $arg, $size) = @_;

    $Modoi::Fetcher::Fetching{$request->uri} ||= Coro::Semaphore->new;
    $Modoi::Fetcher::Fetching{$request->uri}->down;

    http_request $request->method, $request->uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0, Coro::rouse_cb;

    my ($data, $header) = Coro::rouse_wait;

    my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
    $response->request($request);

    $Modoi::Fetcher::Fetching{$request->uri}->up;
    $response;
}

1;
