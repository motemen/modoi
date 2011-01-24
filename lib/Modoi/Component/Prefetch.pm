package Modoi::Component::Prefetch;
use Mouse;

extends 'Modoi::Component';

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('Cache');
    $context->install_component('FindMedia');
    Modoi::Fetcher::Role::Prefetch->meta->apply($context->fetcher);
}

package Modoi::Fetcher::Role::Prefetch;
use Mouse::Role;
use Modoi;
use Coro;

after modify_response => sub {
    my ($self, $res, $req) = @_;

    return unless $res->code eq '200';

    my @media = Modoi->component('FindMedia')->find_media($res, $req->request_uri);
    async {
        foreach my $url (@media) {
            next if Modoi->component('Cache')->has_cache($url);
            Modoi->log(notice => "prefetch $url ...");
            Modoi->fetcher->fetch($url);
        }
    } if @media;
};

1;
