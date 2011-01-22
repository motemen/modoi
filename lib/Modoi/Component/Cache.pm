package Modoi::Component::Cache;
use Mouse;
use Mouse::Util::TypeConstraints;
use Modoi::Response;

# TODO make configurable
has cache => (
    is  => 'rw',
    isa => duck_type(CacheLike => 'get', 'set'),
    default => \&_default_cache,
);

sub _default_cache {
    require CHI;
    return CHI->new(
        driver   => 'File',
        root_dir => '.cache-chi',
    );
}

sub get {
    my ($self, $req) = @_;

    return undef if $req->method ne 'GET';

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
    my ($class, $context) = @_;
    my $self = $class->new;

    Modoi::Fetcher::Role::Cache->meta->apply($context->fetcher);
    Modoi::Proxy::Role::Cache->meta->apply($context->proxy);

    return $self;
}

package Modoi::Component::Cache::Cache::File;
use Mouse;
use MouseX::Types::Path::Class;

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

around request => sub {
    my ($orig, $self, @args) = @_;
    my $req = $args[0];
    my $res = $self->$orig(@args);
    Modoi->component('Cache')->update($res, $req);
    return $res;
};

package Modoi::Proxy::Role::Cache;
use Mouse::Role;
use Modoi;

# TODO Cache-Control, serve 304, etc
around serve => sub {
    my ($orig, $self, @args) = @_;
    my $env = $args[0];
    my $req = $self->prepare_request($env);
    my $res = Modoi->component('Cache')->get($req);
    if ($res) {
        Modoi->log(info => 'serving cache for ' . $req->request_uri);
        return $res;
    } else {
        return $self->$orig(@args);
    }
};

1;
