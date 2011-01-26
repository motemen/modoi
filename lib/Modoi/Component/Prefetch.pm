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
use Coro::Timer qw(sleep);

after modify_response => sub {
    my ($self, $res, $req) = @_;

    return unless $res->code eq '200';

    my @media = Modoi->component('FindMedia')->find_media($res, $req->request_uri);
    async {
        my $i = 0;
        foreach my $url (@media) {
            next if Modoi->component('Cache')->has_cache($url);
            Modoi->log(notice => "prefetch $url");
            Modoi->fetcher->fetch($url);
            if (++$i % 5 == 0) {
                Modoi->log(notice => "prefetched $i, sleep for 3 secs... (from " . $req->request_uri . ')');
                sleep 3;
            }
        }
        Modoi->log(info => "total $i prefetch done (from " . $req->request_uri . ')');
    } if @media;
};

1;
