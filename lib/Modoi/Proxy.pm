package Modoi::Proxy;
use Any::Moose;

use Modoi;
use Modoi::Fetcher;
use LWP::UserAgent;

has 'fetcher', (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    lazy_build => 1,
);

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

sub _build_ua {
    LWP::UserAgent->new(env_proxy => 1);
}

sub process {
    my ($self, $req) = @_;

#   Modoi->log(debug => 'request: ' . $req->as_string);

    my $res = do {
        # TODO should not use fetcher for pages that may redirect
        if (uc $req->method eq 'GET') {
            $self->fetcher->fetch($req);
        } else {
            $self->ua->simple_request($req);
        }
    };

#   Modoi->log(debug => 'response: ' . $res->as_string);

    $res;
}

1;
