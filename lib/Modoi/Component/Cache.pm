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
    require CHI;
    return CHI->new(
        driver   => 'File',
        root_dir => '.cache-chi',
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
    return Modoi::Response->new(@$value);
}

# TODO last-modified みたりキャッシュすべきかどうか判定したり
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

# TODO
# レスポンスの内容をそのまま保存するキャッシュ
# - http/https 区別しない
# - / のあとに勝手に index.html つける

has cache_root => (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

sub _url_to_file {
    my ($self, $url) = @_;
    $url =~ s(^https?://)();
    $url =~ s(/$)(/index.html);
    $url =~ s(/+)(/)g;
    return $self->cache_root->file(split '/', $url);
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

# TODO Cache-Control, serve 304, etc
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
