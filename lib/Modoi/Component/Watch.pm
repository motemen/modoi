package Modoi::Component::Watch;
use Mouse;
use Modoi;
use AnyEvent;
use Coro;
use Coro::Timer;
use Coro::Semaphore;
use HTTP::Config;

extends 'Modoi::Component';

has watch_condition => (
    is  => 'rw',
    isa => 'HTTP::Config',
    default => \&_default_watch_condition,
);

has watchers => (
    is  => 'rw',
    isa => 'HashRef', # { url => watcher }
    default => sub { +{} },
);

has interval => (
    is  => 'rw',
    isa => 'Int',
    default => 300,
);

has semaphore => (
    is  => 'rw',
    isa => 'Coro::Semaphore',
    default => sub {
        my $self = shift;
        warn $self->max_request_at_once;
        return Coro::Semaphore->new($self->max_request_at_once);
    },
    lazy => 1,
);

has max_request_at_once => (
    is  => 'rw',
    isa => 'Int',
    default => 4,
);

has least_request_interval => (
    is  => 'rw',
    isa => 'Int',
    default => 10,
);

sub _default_watch_condition {
    my $config = HTTP::Config->new;
    $config->add(m_domain => '.2chan.net', m_path_match => qr(^/\w+/res/));
    return $config;
}

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('Cache');
    Modoi::Fetcher::Role::Watch->meta->apply($context->fetcher);
}

sub RESTORE_STATE {
    my $self = shift;

    my @urls = @{ Modoi->package_state->{urls} || [] } or return;
    Modoi->log(notice => 'restoring state ...');
    foreach my $url (@urls) {
        $self->start_watching_url($url);
    }
}

sub STORE_STATE {
    my $self = shift;
    Modoi->package_state->{urls} = [ keys %{ $self->watchers } ];
}

sub watch {
    my ($self, $res, $req) = @_;

    my $url = $req->request_uri;
    return if $self->watchers->{$url};

    return unless $res->code eq '200';
    return unless $self->watch_condition->matching($url, $req->as_http_message, $res->as_http_message);

    $self->start_watching_url($url);
}

sub start_watching_url {
    my ($self, $url) = @_;

    Modoi->log(info => "Start watching $url");
    $self->watchers->{$url} = async_pool {
        while (1) {
            Coro::Timer::sleep $self->interval;

            Modoi->log(info => "Timered fetch: $url");
            Modoi->log(debug => 'Semaphore =', $self->semaphore->count);

            $self->semaphore->down;

            my $res = Modoi->fetcher->fetch($url);
            my $original_status = $res->headers->header('X-Modoi-Original-Status');

            Modoi->log(debug => 'Sleep for 10 secs before releasing semaphore...');
            Coro::Timer::sleep $self->least_request_interval;
            $self->semaphore->up;
            Modoi->log(debug => 'Semaphore released -> ' . $self->semaphore->count);

            if ($res->code =~ /^4\d\d$/ || ($original_status && $original_status =~ /^4\d\d$/)) {
                delete $self->watchers->{$url};
                last;
            }
        }

        Modoi->log(info => "Stop watching $url");
    };
}

sub status {
    my $self = shift;
    require URI;
    return [ map { URI->new($_) } keys %{ $self->watchers } ];
}

package Modoi::Fetcher::Role::Watch;
use Mouse::Role;
use Modoi;

after modify_response => sub {
    my ($self, $res, $req) = @_;
    Modoi->component('Watch')->watch($res, $req);
};

1;
