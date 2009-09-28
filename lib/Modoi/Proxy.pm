package Modoi::Proxy;
use Any::Moose;

use Modoi;
use Modoi::Fetcher;
use Modoi::Watcher;
use Modoi::Extractor;
use Modoi::Parser;
use Modoi::DB::Thread;
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

has 'parser', (
    is  => 'rw',
    isa => 'Modoi::Parser',
    default => sub { Modoi::Parser->new },
);

has 'watcher', (
    is  => 'rw',
    isa => 'Modoi::Watcher',
    lazy_build => 1,
);

# XXX これいるかなー
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

sub _build_watcher {
    my $self = shift;
    Modoi::Watcher->new(fetcher => $self->fetcher, on_response => sub { $self->do_prefetch($_[0]) });
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

    if ($res->code =~ /^59\d$/) {
        die $res->headers->header('Reason');
    }

    # if ($res->is_success && $self->config->cond('watch')->pass($res)) {
    if ($res->is_success && $req->uri =~ m<2chan\.net/b/res/>) { # TODO
        $self->watcher->watch($req->uri);
    }

    # if ($res->is_success && $self->config->cond('store')->pass($res)) {
    if ($res->is_success && $req->uri =~ m<2chan\.net/b/res/>) { # TODO
        if (my $thread_info = $self->parser->parse($res)) {
            # TODO ここでいい？
            my $thread = Modoi::DB::Thread->new(
                map { $_ => $thread_info->{$_} } @{Modoi::DB::Thread->meta->columns}
            );
            $thread->uri($req->uri);
            $thread->save($thread->load(speculative => 1) ?  ( update => 1 ) : ());
        }
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
