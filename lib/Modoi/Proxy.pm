package Modoi::Proxy;
use Any::Moose;

use Modoi;
use Modoi::Fetcher;
use Coro;
use LWP::UserAgent;
use HTTP::Request::Common 'GET';

has 'fetcher', (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    lazy_build => 1,
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

has 'ua', (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_fetcher {
    my $self = shift;
    require Cache::FileCache;
    Modoi::Fetcher->new(cache => Cache::FileCache->new);
}

sub _build_ua {
    LWP::UserAgent->new(env_proxy => 1);
}

sub process {
    my ($self, $req) = @_;

    my $res = do {
        # TODO should not use fetcher for pages that may redirect
        if (uc $req->method eq 'GET') {
            $self->fetcher->fetch($req);
        } else {
            $self->ua->simple_request($req);
        }
    };

    if ($res->is_success && $req->uri =~ m<2chan\.net/b/res/>) { # TODO
        $self->watch($req->uri);
    }

    $self->do_prefetch($res);

    $res;
}

sub do_prefetch {
    my ($self, $res) = @_;

    return unless $res->is_success;
    return unless $res->content_type =~ m'^text/';

    foreach my $uri ($self->extractor->extract($res)) {
        Modoi->log(debug => "prefetch $uri");
        async { $self->fetcher->fetch(GET $uri) };
    }
}

# TODO 二重に監視しない
sub watch {
    my ($self, $uri) = @_;

    Modoi->log(notice => "watch $uri");

    my $w; $w = AnyEvent->timer(
        after    => 180,
        interval => 180,
        cb => sub {
            Modoi->log(info => "crawl $uri");
            my $res = $self->fetcher->fetch(GET $uri, Cache_Control => 'no-cache');
            if ($res->is_error) {
                Modoi->log(notice => "unwatch $uri");
                undef $w;
            }
        },
    );
}

1;
