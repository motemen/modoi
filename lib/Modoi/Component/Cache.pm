package Modoi::Component::Cache;
use Mouse;
use Mouse::Util::TypeConstraints;
use Modoi::Response;

extends 'Modoi::Component';

# TODO make configurable
has cache => (
    is  => 'rw',
    isa => duck_type(CacheLike => 'get', 'set'),
    default => \&_default_cache,
);

has override_not_found => (
    is  => 'rw',
    isa => 'Bool',
    default => sub { 1 },
);

sub _default_cache {
    return Modoi::Component::Cache::Cache::File->new(
        cache_root => '.cache',
    );
}

sub has_cache {
    my ($self, $url) = @_;
    return !!$self->cache->get("$url");
}

sub get {
    my ($self, $req, $option) = @_;

    return undef if $req->method ne 'GET';
    
    my $headers = $req->headers;
    # 以下はたぶんスーパーリロードなので従う
    return undef if ($headers->header('Pragma') || '') eq 'no-cache';
    return undef if ($headers->header('Cache-Control') || '') eq 'no-cache';

    unless ($option->{force}) {
        # 以下はたぶん普通のリロードなので従わない場合も
        # キャッシュの日時とか考えるべきだが気にしない
        return undef if $headers->header('If-Modified-Since');
        return undef if ($headers->header('Cache-Control') || '') =~ /^max-age=\d+$/;
    }

    my $value = $self->cache->get($req->request_uri) or return undef;
    my $res = Modoi::Response->new(@$value);
    # Last-Modified がなければキャッシュを返さない (キャッシュはするけど)
    return undef unless $res->headers->header('Last-Modified');
    return $res;
}

# とりあえず全部キャッシュして get 時に返すべきかどうか判定する
sub update {
    my ($self, $res, $req) = @_;

    if ($req->method eq 'GET' && $res->code eq '200') {
        my $url = $req->request_uri;
        Modoi->log(debug => "updating cache -> $url");
        # Content- 系でないヘッダを削除
        $res = (ref $res)->new($res->code, $res->headers->clone->remove_content_headers, $res->content);
        $self->cache->set("$url", $res->finalize);
    }
}

sub INSTALL {
    my ($self, $context) = @_;
    Modoi::Fetcher::Role::Cache->meta->apply($context->fetcher);
    Modoi::Proxy::Role::Cache->meta->apply($context->proxy);
}

sub status {
    my $self = shift;
    return {
        'Cache object' => ref $self->cache,
    };
}

package Modoi::Component::Cache::Cache::File;
use Mouse;
use MouseX::Types::Path::Class;

# レスポンスの content をそのまま保存するキャッシュ
# - ディレクトリに URL の構造をそのまま使用
# - http/https 区別しない
# - / のあとに勝手に index.html つける
# - ヘッダは .meta/ 以下に

has cache_root => (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has cache_meta_root => (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    lazy_build => 1,
);

sub _build_cache_meta_root {
    my $self = shift;
    return $self->cache_root->subdir('.meta');
}

sub _url_to_path_component {
    my ($url) = @_;
    $url =~ s(^https?://)();
    $url =~ s(/$)(/index.html);
    $url =~ s(/+)(/)g;
    return split '/', $url;
}

sub url_to_content_file {
    my ($self, $url) = @_;
    return $self->cache_root->file(_url_to_path_component($url));
}

sub url_to_meta_file {
    my ($self, $url) = @_;
    my @components = _url_to_path_component($url);
    $components[-1] .= '.meta';
    return $self->cache_meta_root->file(@components);
}

sub get {
    my ($self, $url) = @_;
    my $meta_file = $self->url_to_meta_file($url);
    my $content_file = $self->url_to_content_file($url);
    return undef unless -r $meta_file && -r $content_file;
    my $http_res = HTTP::Response->parse("HTTP/1.1 200 OK\r\n" . $meta_file->slurp . "\r\n" . $content_file->slurp);
    return Modoi::Request->new_response_from_http_response($http_res)->finalize;
}

sub set {
    my ($self, $url, $psgi_res) = @_;
    my (undef, $headers, $lines) = @$psgi_res; # ステータスは 200 決め打ち
    my $meta_file = $self->url_to_meta_file($url);
    my $content_file = $self->url_to_content_file($url);
    $meta_file->dir->mkpath;
    $meta_file->openw->print(HTTP::Headers->new(@$headers)->as_string);
    $content_file->dir->mkpath;
    $content_file->openw->print(join "\n", @$lines); # XXX IO::Handle 的なものは未対応 (まあそういうのはこない)
}

package Modoi::Fetcher::Role::Cache;
use Mouse::Role;
use Modoi;

after modify_response => sub {
    my ($self, $res, $req) = @_;
    Modoi->component('Cache')->update($res, $req);
};

package Modoi::Proxy::Role::Cache;
use Mouse::Role;
use Modoi;

# TODO Cache-Control, serve 304, X-Cache, X-Cache-Lookup
around serve => sub {
    my ($orig, $self, @args) = @_;
    my $env = $args[0];
    my $req = $self->prepare_request($env);

    my $cache_component = Modoi->component('Cache');
    my $cached_res = $cache_component->get($req);
    if ($cached_res) {
        Modoi->log(info => 'serving cache for', $req->request_uri);
        return $cached_res;
    }

    my $res = $self->$orig(@args);
    if ($res->code eq '404' && $cache_component->override_not_found) {
        if (my $cached_res = $cache_component->get($req, { force => 1 })) {
            Modoi->log(info => 'overriding 404:', $req->request_uri);
            $res = $cached_res;
            $res->headers->push_header('X-Modoi-Source' => 'Cache');
            $res->headers->push_header('X-Modoi-Original-Status' => '404');
        }
    }
    return $res;
};

1;
