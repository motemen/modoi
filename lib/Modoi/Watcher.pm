package Modoi::Watcher;
use Any::Moose;

use Modoi;
use Coro;
use HTTP::Request::Common;

has 'fetcher', (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    lazy_build => 1,
);

has 'timers', (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
);

has 'interval', (
    is  => 'rw',
    isa => 'Int',
    default => 180,
);

has 'on_response', (
    is  => 'rw',
    isa => 'CodeRef',
    default => sub { sub {} },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub watch {
    my ($self, $uri) = @_;

    $self->timers->{$uri} ||= do {
        Modoi->log(notice => "watch $uri");
        AnyEvent->timer(
            after    => $self->interval,
            interval => $self->interval,
            cb => unblock_sub {
                Modoi->log(info => "crawl $uri");
                my $res = $self->fetcher->fetch(GET $uri, Cache_Control => 'no-cache');
                $self->on_response->($res);
                $self->unwatch($uri) if $res->is_error;
            },
        );
    };
}

sub unwatch {
    my ($self, $uri) = @_;

    Modoi->log(notice => "unwatch $uri");

    delete $self->timers->{$uri};
}

sub status { shift->timers }

1;
