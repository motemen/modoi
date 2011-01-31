package Modoi::Component::WebProxy::TouchView;
use Mouse;

extends 'Modoi::Component';

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
    $context->install_component('WebProxy');
    Modoi::Internal::Engine::WebProxy::Role::TouchView->meta->apply(
        Modoi::Internal::Engine::WebProxy->meta
    );
}

package Modoi::Internal::Engine::WebProxy::Role::TouchView;
use Mouse::Role;
use Modoi;
use Text::Xslate qw(html_builder html_escape);
use DateTime::Format::Strptime; # xslate の中で require すると変になることがあるので

after modify_proxy_response => sub {
    my ($self, $res, $req, $base) = @_;

    my $parsed = Modoi->component('ParseHTML')->parse($res, $req->request_uri)
        or return;
    $req->header('User-Agent') =~ /iPhone|Android/ or return;

    $self->tx->{function}->{html_br} ||= html_builder \&html_br;

    my $content;
    if ($parsed->isa('WWW::Futaba::Parser::Result::Index')) {
        $content = $self->tx->render('webproxy/touchview/index.tx',   { req => $req, index => $parsed });
    } elsif ($parsed->isa('WWW::Futaba::Parser::Result::Thread')) {
        $content = $self->tx->render('webproxy/touchview/thread.tx',  { req => $req, thread => $parsed });
    } elsif ($parsed->isa('WWW::Futaba::Parser::Result::Catalog')) {
        $content = $self->tx->render('webproxy/touchview/catalog.tx', { req => $req, catalog => $parsed });
    }
    
    if ($content) {
        utf8::encode $content;
        $res->content($content);
        $res->content_length(length $content);
    }
};

sub html_br {
    my $string = shift;
    return join '<br/>', map { html_escape($_) } split /[\r\n]/, $string;
}

1;
