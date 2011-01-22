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
    foreach ($req->headers->header_field_names) {
        $req->headers->remove_header($_) if /^Proxy-/i;
    }
    return $self->fetcher->request($req);
}

1;
