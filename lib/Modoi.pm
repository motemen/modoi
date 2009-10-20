package Modoi;
use strict;
use warnings;
use Modoi::Context;

# XXX このパッケージなんなの…

sub context { our $Context ||= Modoi::Context->new }

sub log {
    my $class = shift;
    $class->context->log(@_);
}

sub fetcher_status {
    my $class = shift;

    my %status;
    foreach my $uri ($class->context->fetcher->uris_on_progress) {
        my $progress = LWP::UserAgent::AnyEvent::Coro->progress($uri);
        my $status = $status{$uri} = {
            current => $progress && $progress->[0] || 0,
            total   => $progress && $progress->[1] || 0,
        };
        $status->{percentage} = 100 * $status->{current} / $status->{total} if $status->{current} && $status->{total};
    }
    \%status;
}

sub watcher_status {
    my $class = shift;

    my %status;
    foreach my $uri (keys %{$class->context->watcher->timers}) {
        $status{$uri} = Modoi::DB::Thread->new(uri => $uri)->load;
    }
    \%status;
}

sub threads {
    my $self = shift;
    Modoi::DB::Thread::Manager->get_threads(sort_by => 'updated_on DESC', @_);
}

1;
