package Modoi::Internal::Engine;
use Mouse;
use Modoi;
use Text::Xslate;

sub tx {
    our $tx ||= Text::Xslate->new(
        path => [ 'root' ],
    );
}

sub html {
    my $self = shift;
    for (@_) {
        utf8::encode $_ if utf8::is_utf8 $_;
    }
    return [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ @_ ] ];
}

sub default {
    my ($self, $req) = @_;
    return $self->html($self->tx->render('index.tx', { context => Modoi->context }));
}

# FIXME 暫定
sub render {
    my ($self, $string, $args) = @_;
    $args->{context} ||= Modoi->context;
    my $template = <<__TX__;
: cascade _wrapper
: override content -> {
$string
: }
__TX__
    return $self->html($self->tx->render_string($template, $args));
}

sub render_template {
    my ($self, $file, $args) = @_;
    $args->{context} ||= Modoi->context;
    return $self->html($self->tx->render($file, $args));
}

1;
