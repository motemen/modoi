package Modoi::Component::Watch;
use Mouse;
use Modoi;
use AnyEvent;
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
    default => 30,
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

sub watch {
    my ($self, $res, $req) = @_;

    my $url = $req->request_uri;
    return if $self->watchers->{$url};

    return unless $res->code eq '200';
    return unless $self->watch_condition->matching($url, $req->as_http_message, $res->as_http_message);

    $self->watchers->{$url} = AE::timer(
        $self->interval,
        $self->interval,
        sub {
            Modoi->log(info => "Timered fetch: $url");
            my $res = Modoi->fetcher->fetch($url);
            my $original_status = $res->headers->header('X-Modoi-Original-Status');
            if ($res->code =~ /^4\d\d$/ || ($original_status && $original_status =~ /^4\d\d$/)) {
                Modoi->log(info => "Stop watching $url");
                delete $self->watchers->{$url};
            }
        },
    );
    Modoi->log(info => "Start watching $url");
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
