package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Config;
use Modoi::Extractor;
use Modoi::Util::HTTP qw(
    should_serve_content
    may_return_not_modified
    may_serve_cache
    one_year_from_now
);

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

has 'on_fresh_response', (
    is  => 'rw',
    isa => 'CodeRef',
    default => sub { sub { } },
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

sub fetch_cache {
    my ($self, $uri) = @_;
    $self->_fetch_simple($uri, NoNetwork => 1);
}

sub _fetch_simple {
    my ($self, $uri, %args) = @_;
    my $fetch_res = URI::Fetch->fetch(
        "$uri",
        Cache         => $self->cache,
        ForceResponse => 1,
        UserAgent     => $self->ua,
        %args,
    ) or return do {
        my $res = HTTP::Response->new(599);
        $res->header(X_Modoi_Reason => 'URI::Fetch returned undef');
        $res;
    };
    my $res = $fetch_res->as_http_response;
    $res->headers->header(X_Modoi_Source => 'cache') if $args{NoNetwork};
    $res;
}

# TODO ながい
sub fetch {
    my ($self, $req) = @_;

    my %fetch_args = (
        ETag          => scalar $req->header('If-None-Match'),
        LastModified  => scalar $req->header('If-Modified-Since'),
    );

    if (may_serve_cache($req)) {
        my $cache_res = $self->fetch_cache($req->uri);
        if ($cache_res->is_success) {
            if ($self->config->condition('serve_cache')->pass($cache_res)) {
                # キャッシュから返却
                if (may_return_not_modified($req)) {
                    Modoi->log(debug => 'return NOT MODIFIED for ' . $req->uri);
                    return HTTP::Response->new(RC_NOT_MODIFIED);
                } else {
                    Modoi->log(debug => 'serve cache for ' . $req->uri);
                    $cache_res->headers->header(Expires => one_year_from_now);
                    return $cache_res;
                }
            }
        }
    }

    Modoi->log(debug => '>>> fetch ' . $req->uri);

    if (should_serve_content($req)) {
        # スーパーリロードの場合はキャッシュをうまいこと無視しないといけない
        # これだとレスポンスを格納できないのでダメそう FIXME
        %fetch_args = ( Cache => '' );
    }

    $UriSemaphore{$req->uri} ||= Coro::Semaphore->new;
    if ($UriSemaphore{$req->uri}->count <= 0) {
        Modoi->log(debug => $req->uri . ': currently fetching');
        $fetch_args{NoNetwork} = 1; # 他のジョブが取ってきているキャッシュを期待する
    }

    my $guard = $UriSemaphore{$req->uri}->guard;
    my $fetch_res = $self->_fetch_simple($req->uri, %fetch_args);

    if ($fetch_args{NoNetwork} && $fetch_res->is_error) {
        # おそらく別の Coro が fetch 中だったけど失敗したのでキャッシュを取得できなかったという状況
        # じゃあセマフォを消してもう一回
        undef $guard;
        return $self->fetch($req);
    }

    Modoi->log(
        debug => '<<< ' . $req->uri . ' (' . $fetch_res->code . do { my $source = $fetch_res->header('X-Modoi-Source'); $source ? ",$source" : '' } . ')'
    );

    if ($fetch_res->code == RC_NOT_FOUND && may_serve_cache($req)) {
        # serve cache
        Modoi->log(info => 'serving cache for ' . $req->uri);
        my $cache_res = $self->fetch_cache($req->uri);
        $fetch_res = $cache_res if $cache_res->is_success;
    }

    my $res = $fetch_res;
    $res->request($req) unless $res->request;

    if (!$fetch_res->is_error && should_serve_content($req)) {
        # えーとなんだっけ、何だかの理由で必要
        $res->code(RC_OK);
        $res->header(Content_Type => $fetch_res->content_type);
    }

    if ($self->config->condition('serve_cache')->pass($res)) {
        # キャッシュを返してもよいコンテンツには Expires: ヘッダを付与してやる
        $res->headers->header(Expires => one_year_from_now);
    }

    if ($res->is_success
            && ($res->header('X-Modoi-Source') || '') ne 'cache'
            && $self->config->condition('save_thread')->pass($res)) {
        $self->on_fresh_response->($res);
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
