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
    return {
       cache => {
         module => 'Modoi::Fetcher::FileCache',
         args   => { cache_root => '.cache' },
       }
    };
}

has 'cache', (
    is  => 'rw',
    isa => 'Object', # XXX duck_type(['get', 'set']);
    lazy_build => 1,
);

has 'write_only_cache', (
    is  => 'rw',
    isa => 'Object', # XXX
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

sub _build_write_only_cache {
    my $self = shift;
    my $cache = $self->cache;

    {
        package Modoi::Fetcher::Cache::WriteOnly;
        sub get { undef }
        sub set { my $self = shift; $$self->set(@_) }
    }

    bless \$cache, 'Modoi::Fetcher::Cache::WriteOnly';
}

sub simple_request {
    my $self = shift;
    $self->ua->simple_request(@_);
}

sub fetch_cache {
    my ($self, $uri) = @_;
    $self->_fetch_simple($uri, NoNetwork => 1);
}

sub _uri_fetch_args {
    my $self = shift;
    my $cache = $self->cache;
    if ($cache->can('uri_fetch_args')) {
        return (
            UserAgent     => $self->ua,
            ForceResponse => 1,
            $cache->uri_fetch_args,
        );
    } else {
        return (
            UserAgent     => $self->ua,
            ForceResponse => 1,
            Cache         => $cache,
        );
    }
}

sub _fetch_simple {
    my ($self, $uri, %args) = @_;
    my $fetch_res = URI::Fetch->fetch(
        "$uri",
        $self->_uri_fetch_args,
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
    my $class = ref $self;

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

    if (!may_serve_cache($req)) {
        # スーパーリロードの場合はキャッシュをうまいこと無視しないといけない
        %fetch_args = ( Cache => $self->write_only_cache );
    }

    if ($class->currently_fetching($req->uri)) {
        Modoi->log(debug => $req->uri . ': currently fetching');
        $fetch_args{NoNetwork} = 1; # 他のジョブが取ってきているキャッシュを期待する
    }

    my $guard = $class->fetch_guard($req->uri); # 他のジョブが取ってきていればここでストップする

    Modoi->log(debug => '>>> fetch ' . $req->uri);

    my $fetch_res = $self->_fetch_simple($req->uri, %fetch_args);

    undef $guard;

    if ($fetch_args{NoNetwork} && $fetch_res->is_error) {
        # おそらく別の Coro が fetch 中だったけど失敗したのでキャッシュを取得できなかったという状況
        # じゃあセマフォを消してもう一回
        Modoi->log(error => 'failed to retrieve cache; retry ' . $req->uri);
        return $self->fetch($req);
    }

    Modoi->log(
        debug => '<<< ' . $req->uri . ' (' . $fetch_res->code . do { my $source = $fetch_res->header('X-Modoi-Source'); $source ? ",$source" : '' } . ')'
    );

    if ($fetch_res->is_error) {
        Modoi->log(
            info => $req->uri . ': ' . $fetch_res->message
        );
    }

    if ($fetch_res->code == RC_NOT_FOUND && may_serve_cache($req)) {
        # serve cache
        Modoi->log(info => 'serving cache for ' . $req->uri);
        my $cache_res = $self->fetch_cache($req->uri);
        $fetch_res = $cache_res if $cache_res->is_success;
    }

    my $res = $fetch_res;
    $res->request($req) unless $res->request;

    if (!$fetch_res->is_error && !may_return_not_modified($req)) {
        # 304 が入ってる場合もあるので 200 にリセット
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

our %UriSemaphore;

sub cancel {
    my ($class, $uri) = @_;
    Modoi->log(info => "fetching $uri will be cancelled");
    LWP::UserAgent::AnyEvent::Coro->cancel($uri);
    delete $UriSemaphore{$uri};
}

sub currently_fetching {
    my ($class, $uri) = @_;
    my $sem = $UriSemaphore{$uri} or return;
    return $sem->count <= 0;
}

sub fetch_guard {
    my ($class, $uri) = @_;
    ($UriSemaphore{$uri} ||= Coro::Semaphore->new)->guard;
}

sub uris_on_progress {
    grep { $UriSemaphore{$_}->count == 0 } keys %UriSemaphore;
}

sub logger_name {
    my $class = shift;
    sprintf '%s [%d]', __PACKAGE__, scalar $class->uris_on_progress;
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

    $request->remove_header('Accept-Encoding'); # XXX とりあえず

    my $t = [ Time::HiRes::gettimeofday ];

    my $uri = $request->uri;
    my $data;

    $request->headers->header(User_Agent => $UserAgent) if $UserAgent;

    $Session{$uri}{guard} = http_request $request->method, $uri,
        timeout => $self->timeout, headers => $request->headers, recurse => 0,
        on_body => sub {
            my ($partial_data, $header) = @_;
            $data .= $partial_data;
            Modoi->log(debug => sprintf("$uri: %d/%s", length $data, $header->{'content-length'} || '-'));
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
