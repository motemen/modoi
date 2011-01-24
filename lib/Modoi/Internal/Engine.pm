package Modoi::Internal::Engine;
use Mouse;
use Text::Xslate;

sub tx {
    our $tx ||= Text::Xslate->new(
        path => [ 'root' ],
    );
}

sub html {
    my $self = shift;
    return [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ @_ ] ];
}

sub default {
    my ($self, $req) = @_;
    return $self->html($self->tx->render('index.tx', { context => Modoi->_context }));
}

# FIXME 暫定
sub render {
    my ($self, $string, $args) = @_;
    my $template = <<__TX__;
: cascade _wrapper
: override content -> {
$string
: }
__TX__
    return $self->html($self->tx->render_string($template, $args));
}

1;
