package Modoi::Proxy;
use Any::Moose;
use LWP::UserAgent;

has 'ua', (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_ua {
    LWP::UserAgent->new(env_proxy => 1);
}

sub _process {
    my ($self, $req) = @_;
    $self->ua->simple_request($req);
}

1;
