package Modoi::Fetcher;
use Any::Moose;

use Modoi;
use Modoi::Extractor;

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
    default => sub {
        LWP::UserAgent::AnyEvent->new;
    },
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub fetch_uri {
    my ($self, $uri) = splice @_, 0, 2;

    Modoi->log(debug => "fetch $uri");

    my $fetch_res;
    $fetch_res = URI::Fetch->fetch(
        "$uri",
        ForceResponse => 1,
        UserAgent     => $self->ua,
        Cache         => $self->cache,
        @_,
    );

#   $self->do_prefetch($fetch_res->http_response);
    $fetch_res;
}

sub fetch {
    my ($self, $req) = @_;

    my $fetch_res = $self->fetch_uri(
        $req->uri,
        ETag         => scalar $req->header('If-None-Match'),
        LastModified => scalar $req->header('If-Modified-Since'),
    );

    my $res = $fetch_res->http_response;
    if (!$fetch_res->is_error && _should_serve_content($req)) {
        $res->code(200);
        $res->content($fetch_res->content);
        $res->header(Content_Type => $fetch_res->content_type);
        $res->remove_header('Content-Encoding'); # XXX
    }
    $res;
}

sub do_prefetch {
    my ($self, $res) = @_;
    my $result = $self->extractor->extract($res);
    foreach (@{$result->{images}}) {
        Modoi->log(debug => "prefetch $_");
        $self->fetch_uri($_);
    }
}

sub _should_serve_content {
    my ($req) = @_;

    ($req->header('Pragma')        || '') eq 'no-cache' ||
    ($req->header('Cache-Control') || '') eq 'no-cache' ||
    !$req->header('If-Modified-Since');
}

# From Remedie, lib/Plagger/UserAgent.pm
package LWP::UserAgent::AnyEvent;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw( agent timeout ));

use AnyEvent::HTTP;
use AnyEvent;

$AnyEvent::HTTP::MAX_PER_HOST = 16; # :->

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub request {
    my($self, $request) = @_;

    my $headers = $request->headers;
    $headers->{'user-agent'} = $self->agent;

    my $w = AnyEvent->condvar;
    http_request $request->method, $request->uri,
        timeout => 30, headers => $headers, sub { $w->send(@_) };
    my($data, $header) = $w->recv;

    return HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
}

1;
