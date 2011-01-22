package Modoi::Proxy;
use Mouse;
use Modoi::Fetcher;

has fetcher => (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    default => sub { Modoi::Fetcher->new },
);

sub serve {
    my ($self, $req) = @_;
    return $self->fetcher->request($req);
}

1;
