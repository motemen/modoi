package Modoi::Component::ParseHTML;
use Mouse;
use WWW::Futaba::Parser;

sub parse {
    my ($self, $res, $url) = @_;
    if (($res->headers->header('Content-Type') || '') ne 'text/html') {
        return undef;
    }
    return Modoi->session_cache->{$res} ||= do {
        my $parser = WWW::Futaba::Parser->parser_for_url($url);
        $parser && $parser->parse($res->as_http_message->decoded_content);
    };
}

sub INSTALL {
    my ($class, $context) = @_;
    return $class->new;
}

1;
