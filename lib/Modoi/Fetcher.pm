package Modoi::Fetcher;
use Any::Moose;

use Modoi;
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
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub fetch_uri {
    my ($self, $uri) = splice @_, 0, 2;
    Modoi->log(debug => "fetch $uri");
    URI::Fetch->fetch(
        "$uri",
        ForceResponse => 1,
        UserAgent     => $self->ua,
        Cache         => $self->cache,
        @_,
    );
}

sub fetch {
    my ($self, $req) = @_;

    my $fetch_res = $self->fetch_uri(
        $req->uri,
        ETag          => scalar $req->header('If-None-Match'),
        LastModified  => scalar $req->header('If-Modified-Since'),
    );

    my $res = $fetch_res->http_response;
    if (!$fetch_res->is_error && $self->should_serve_content($req)) {
        $res->code(200);
        $res->content($fetch_res->content);
        $res->header(Content_Type => $fetch_res->content_type);
        $res->remove_header('Content-Encoding'); # XXX
    }
    $res;
}

sub should_serve_content {
    my ($self, $req) = @_;

       ($req->header('Pragma') || '')        eq 'no-cache'
    || ($req->header('Cache-Control') || '') eq 'no-cache'
    || !$req->header('If-Modified-Since');
}

1;
