package Modoi::Component::UseBrowserCache;
use Mouse;
use HTTP::Config;

extends 'Modoi::Component';

has condition => (
    is  => 'rw',
    isa => 'HTTP::Config',
    default => \&_default_condition,
);

sub _default_condition {
    my $config = HTTP::Config->new;
    $config->add(m_media_type => 'image/*');
    return $config;
}

sub INSTALL {
    my ($self, $context) = @_;
    Modoi::Fetcher::Role::UseBrowserCache->meta->apply($context->fetcher);
    Modoi::Proxy::Role::UseBrowserCache->meta->apply($context->proxy);
}

package Modoi::Fetcher::Role::UseBrowserCache;
use Mouse::Role;
use Modoi;
use DateTime;
use DateTime::Format::HTTP;

after modify_response => sub {
    my ($self, $res, $req) = @_;

    Modoi->component('UseBrowserCache')->condition->matching(
        $req->request_uri, $req->as_http_message, $res->as_http_message
    ) or return;

    my $dt = DateTime->now->add(years => 1);
    $dt->set_formatter('DateTime::Format::HTTP');
    $res->headers->header(Expires => "$dt");
};

package Modoi::Proxy::Role::UseBrowserCache;
use Mouse::Role;
use Modoi;
use Modoi::Response;

around serve => sub {
    my ($orig, $self, @args) = @_;
    my $env = $args[0];
    my $req = $self->prepare_request($env);

    my $headers = $req->headers;
    if ($headers->header('If-Modified-Since') || $headers->header('If-None-Match')) {
        # ブラウザがキャッシュを持ってる場合はサーバに問い合わせずに 304 を返す
        my $cached_res = Modoi->component('Cache')->get($req);
        if ($cached_res && Modoi->component('UseBrowserCache')->condition->matching(
            $req->request_uri, $req->as_http_message, $cached_res->as_http_message
        )) {
            Modoi->log(debug => 'immediately reply 304 for', $req->request_uri);
            return Modoi::Response->new(304, [], []);
        }
    }

    return $self->$orig(@args);
};

1;
