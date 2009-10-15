package Modoi::Watcher;
use Any::Moose;

with 'Modoi::Role::Configurable';

use Modoi;
use AnyEvent;
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

sub DEFAULT_CONFIG { +{} }

sub start_watching_if_necessary {
    my ($self, $res) = @_;
    return unless $self->config->condition('watch')->pass($res);
    $self->watch($res->request->uri);
}

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
                $self->unwatch($uri) unless $res->is_success;
            },
        );
    };
}

sub unwatch {
    my ($self, $uri) = @_;

    Modoi->log(notice => "unwatch $uri");

    delete $self->timers->{$uri};
}

1;
