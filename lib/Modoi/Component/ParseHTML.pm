package Modoi::Component::ParseHTML;
use Mouse;
use WWW::Futaba::Parser;

extends 'Modoi::Component';

sub parse {
    my ($self, $res, $url) = @_;
    if (($res->headers->header('Content-Type') || '') ne 'text/html') {
        return undef;
    }
    return $res->data->{ParseHTML} ||= do {
        my $parser = WWW::Futaba::Parser->parser_for_url($url);
        $parser && eval { $parser->parse($res->as_http_message->decoded_content) }; # TODO
    };
}

sub status {
    my $self = shift;
    return { 'WWW::Futaba::Parser version' => $WWW::Futaba::Parser::VERSION };
}

1;
