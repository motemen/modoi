package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Config;
use Modoi::Extractor;
use Modoi::DB::Thread;
use Modoi::Util::HTTP qw(should_serve_content may_return_not_modified may_serve_cache one_year_from_now);

use Coro;
use Coro::AnyEvent;
use Coro::Semaphore;

use List::MoreUtils qw(uniq);
use HTTP::Status;
use HTTP::Request::Common qw(GET);
use URI::Fetch;
use UNIVERSAL::require;

with 'Modoi::Role::Configurable';

sub DEFAULT_CONFIG {
    +{ cache => { module => 'Cache::MemoryCache' } };
}

has 'cache', (
    is  => 'rw',
    isa => 'Cache::Cache',
    lazy_build => 1,
);

has 'ua', (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent::AnyEvent::Coro->new(timeout => 30) },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_cache {
    my $self = shift;
    my $cache_config = $self->config->{cache};
    $cache_config->{module}->require or die $@;
    $cache_config->{module}->new($cache_config->{args});
}

our %UriSemaphore;

sub simple_request {
    my $self = shift;
    $self->ua->simple_request(@_);
}

# XXX returns Fetch::URI::Response
sub fetch_cache {
    my ($self, $uri) = @_;
    $self->_fetch_simple($uri, NoNetwork => 1);
}

# TODO こいつが HTTP::Reponse を返したほうがよい？
sub _fetch_simple {
    my ($self, $uri, %args) = @_;
    URI::Fetch->fetch(
        "$uri",
        Cache         => $self->cache,
        ForceResponse => 1,
        UserAgent     => $self->ua,
        %args,
    );
}

# TODO ながい
sub fetch {
    my ($self, $req) = @_;

    my %fetch_args = (
        ETag          => scalar $req->header('If-None-Match'),
        LastModified  => scalar $req->header('If-Modified-Since'),
    );

    if (may_serve_cache($req)) {
        if (my $cache_res = $self->fetch_cache($req->uri)) {
            if ($self->config->condition('serve_cache')->pass($cache_res)) {
                if (may_return_not_modified($req)) {
                    Modoi->log(debug => 'return NOT MODIFIED for ' . $req->uri);
                    return HTTP::Response->new(RC_NOT_MODIFIED);
                } else {
                    Modoi->log(debug => 'serve cache for ' . $req->uri);
                    my $res = $cache_res->as_http_response;
                    $res->headers->header(Expires => one_year_from_now);
                    return $res;
                }
            }
        }
    }

    Modoi->log(debug => '>>> fetch ' . $req->uri);

    $UriSemaphore{$req->uri} ||= Coro::Semaphore->new;
    if ($UriSemaphore{$req->uri}->count <= 0) {
        Modoi->log(debug => $req->uri . ': currently fetching');
        $fetch_args{NoNetwork} = 1; # キャッシュを期待する
    }

    my $guard = $UriSemaphore{$req->uri}->guard;
    my $fetch_res = $self->_fetch_simple($req->uri, %fetch_args);

    unless ($fetch_res) {
        # おそらく別の Coro が fetch 中だったけど失敗したのでキャッシュを取得できなかったという状況
        die q<Can't happen> unless $fetch_args{NoNetwork} == 1;
        undef $guard;
        return $self->fetch($req);
    }

    Modoi->log(debug => '<<< ' . $req->uri . ' (' . ($fetch_res ? $fetch_res->http_status || '200, cache' : 404) . ')');

    my $http_status = $fetch_res->http_status || RC_OK;

    my $from_cache;
    if ($http_status == RC_NOT_FOUND && may_serve_cache($req)) {
        # serve cache
        Modoi->log(info => 'serving cache for ' . $req->uri);
        $fetch_res = $self->fetch_cache($req->uri) || $fetch_res;
        $from_cache++;
    }

    my $res = $fetch_res->as_http_response($req);

    if (!$fetch_res->is_error && should_serve_content($req)) {
        # えーとなんだっけ
        $res->code(RC_OK);
        $res->header(Content_Type => $fetch_res->content_type);
    }

    if ($self->config->condition('serve_cache')->pass($res)) {
        # キャッシュを返してもよいコンテンツには Expires: ヘッダを付与してやる
        $res->headers->header(Expires => one_year_from_now);
    }

    if ($from_cache) {
        # キャッシュから掘り起こされたコンテンツはマークしておく
        $res->headers->header(X_Modoi_Source => 'cache');
    }

    if ($res->is_success && !$fetch_args{NoNetwork} && !$from_cache && $self->config->condition('save_thread')->pass($res)) {
        Modoi->log(info => 'saving thread ' . $req->uri);
        Modoi::DB::Thread->save_response($res);
    }

    $res;
}

# XXX
sub cancel {
    my ($class, $uri) = @_;
    Modoi->log(info => "fetching $uri will be cancelled");
    # TODO セマフォ削除…というかセマフォは LWP::UA::Coro にもっていくべきなのでは
    LWP::UserAgent::AnyEvent::Coro->cancel($uri);
}

sub uris_on_progress {
    grep { $UriSemaphore{$_}->count == 0 } keys %UriSemaphore;
}

sub logger_name {
    sprintf '%s [%d]', __PACKAGE__, (scalar grep { $_->count == 0 } values %UriSemaphore);
}

sub URI::Fetch::Response::as_http_response {
    my ($self, $req) = @_;
    my $res = $self->http_response || do {
        my $res = HTTP::Response->new($self->http_status || RC_OK);
        $res->header(
            ETag          => $self->etag,
            Last_Modified => $self->last_modified,
            Content_Type  => $self->content_type,
        );
        $res;
    };
    $res->content($self->content);
    $res->remove_header('Content-Encoding');
    $res->remove_header('Transfer-Encoding');
    $res->request($req) unless $res->request;
    $res;
}

package LWP::UserAgent::AnyEvent::Coro;
use base 'LWP::UserAgent';

use AnyEvent;
use AnyEvent::HTTP;
use Coro;
use Time::HiRes;

$AnyEvent::HTTP::MAX_PER_HOST = 8; # as Firefox default

our %Session;
our $UserAgent;

sub cancel {
    my ($class, $uri) = @_;
    if (my $guard = delete $Session{$uri}{guard}) {
        undef $guard;
    }
}

sub progress {
    my ($class, $uri) = @_;
    $Session{$uri}{progress};
}

sub send_request {
    my $self = shift;
    my ($request, $arg, $size) = @_;

    if (uc $request->method ne 'GET') {
        return $self->SUPER::send_request(@_);
    }

    my $t = [ Time::HiRes::gettimeofday ];

    my $uri = $request->uri;
    my $data;

    $request->headers->header(User_Agent => $UserAgent) if $UserAgent;

    $Session{$uri}{guard} = http_request $request->method, $uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0,
        on_body => sub {
            my ($partial_data, $header) = @_;
            $data .= $partial_data;
            $Session{$uri}{progress} = [ length $data, $header->{'content-length'} ];
            1;
        },
        Coro::rouse_cb;

    (undef, my $header) = Coro::rouse_wait;

    my $response = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
    $response->request($request);

    Modoi->log(debug => sprintf '%s %.2fs', $request->uri, Time::HiRes::tv_interval $t);

    $response;
}

1;
