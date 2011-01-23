package Modoi::Component::ExtendExpires;
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
    Modoi::Fetcher::Role::ExtendExpires->meta->apply($context->fetcher);
}

package Modoi::Fetcher::Role::ExtendExpires;
use Mouse::Role;
use Modoi;
use DateTime;
use DateTime::Format::HTTP;

after modify_response => sub {
    my ($self, $res, $req) = @_;

    Modoi->component('ExtendExpires')->condition->matching(
        $req->request_uri, $req->as_http_message, $res->as_http_message
    ) or return;

    my $dt = DateTime->now->add(years => 1);
    $dt->set_formatter('DateTime::Format::HTTP');
    $res->headers->header(Expires => "$dt");
};

1;
