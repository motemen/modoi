package Modoi::Proxy;
use Any::Moose;

use Modoi;
use Modoi::Fetcher;
use Modoi::Watcher;
use Modoi::Extractor;
use Coro;
use HTTP::Request::Common 'GET';

has 'fetcher', (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    default => sub { Modoi::Fetcher->new },
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

has 'watcher', (
    is  => 'rw',
    isa => 'Modoi::Watcher',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_watcher {
    my $self = shift;
    Modoi::Watcher->new(fetcher => $self->fetcher, on_response => sub { $self->do_prefetch($_[0]) });
}

sub process {
    my ($self, $req) = @_;

    my $res = do {
        local $LWP::UserAgent::AnyEvent::Coro::UserAgent = $req->headers->header('User-Agent');
        if (uc $req->method eq 'GET') {
            my $res = $self->fetcher->fetch($req);
            [ $res->redirects ]->[0] || $res;
        } else {
            $self->fetcher->simple_request($req);
        }
    };

    if ($res->code =~ /^59\d$/) {
        die $res->headers->header('Reason');
    }

    if (($res->headers->header('X-Modoi-Source') || '') ne 'cache') {
        $self->watcher->start_watching_if_necessary($res);
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

1;
