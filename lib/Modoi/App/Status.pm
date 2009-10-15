package Modoi::App::Status;
use Any::Moose;
use Modoi;

extends 'Modoi::App';

no Any::Moose;

__PACKAGE__->meta->make_immutable;

sub fetcher_status {
    my %status;
    foreach my $uri (Modoi->context->fetcher->uris_on_progress) {
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
    my %status;
    foreach my $uri (keys %{Modoi->context->watcher->timers}) {
        $status{$uri} = Modoi::DB::Thread->new(uri => $uri)->load;
    }
    \%status;
}

1;
