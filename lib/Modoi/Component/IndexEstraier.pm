package Modoi::Component::IndexEstraier;
use Mouse;
use Modoi;
use Search::Estraier;
use Try::Tiny;

extends 'Modoi::Component';

has node_url => (
    is  => 'rw',
    isa => 'Str',
    default => 'http://localhost:1978/node/modoi',
);

has node_user => (
    is  => 'rw',
    isa => 'Str',
    default => 'admin',
);

has node_password => (
    is  => 'rw',
    isa => 'Str',
    default => 'admin',
);

has node => (
    is  => 'rw',
    isa => 'Search::Estraier::Node',
    lazy_build => 1,
);

sub _build_node {
    my $self = shift;

    return Search::Estraier::Node->new(
        url => $self->node_url,
        user => $self->node_user,
        passwd => $self->node_password,
        croak_on_error => 1,
    );
}

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
    Modoi::Fetcher::Role::IndexEstraier->meta->apply($context->fetcher);
}

sub _utf8_off ($) {
    my $s = shift;
    utf8::encode $s if utf8::is_utf8 $s;
    return $s;
}

sub add {
    my ($self, $res, $req) = @_;

    my $url = $req->request_uri;
    my $parsed = Modoi->component('ParseHTML')->parse($res, $url) or return;
    if ($parsed->isa('WWW::Futaba::Parser::Result::Thread')) {
        my $doc = Search::Estraier::Document->new;
        $doc->add_attr('@uri', $req->request_uri);
        $doc->add_attr('@title', _utf8_off $parsed->body);
        foreach ($parsed, $parsed->posts) {
            $doc->add_text(_utf8_off $_->body);
        }
        try {
            $self->node->put_doc($doc);
            Modoi->log(info => "successfully indexed $url");
        } catch {
            Modoi->log(warn => "error indexing $url: $_");
        }
    }
}

package Modoi::Fetcher::Role::IndexEstraier;
use Mouse::Role;

after modify_response => sub {
    my ($self, $res, $req) = @_;
    return unless $res->code eq '200';
    Modoi->component('IndexEstraier')->add($res, $req);
};

1;
