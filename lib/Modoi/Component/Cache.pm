package Modoi::Component::Cache;
use Mouse;
use Mouse::Util::TypeConstraints;

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

# TODO last-modified みたりキャッシュすべきかどうか判定したり
sub update {
    my ($self, $res, $req) = @_;

    if ($req->method eq 'GET') {
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
    my $cache = Modoi->component('Cache');
    $cache->update($res, $req);
    return $res;
};

1;
