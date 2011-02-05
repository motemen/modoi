package Modoi::Component::ParseHTML;
use Mouse;
use WWW::Futaba::Parser;

extends 'Modoi::Component';

sub parse {
    my ($self, $res, $url) = @_;
    if ($res->code ne '200') {
        return undef;
    }
    if ($res->content_type !~ m(^text/html\b)) {
        return undef;
    }
    return $res->data->{ParseHTML} ||= do {
        my $parser = WWW::Futaba::Parser->parser_for_url($url);
        my $result = $parser && eval { $parser->parse($res->as_http_message->decoded_content) }; # TODO 失敗したらファイル残す
        Modoi->log(warn => 'parse failed:', $url, $@) if $@;
        $result;
    };
}

sub status {
    my $self = shift;
    return { 'WWW::Futaba::Parser version' => $WWW::Futaba::Parser::VERSION };
}

1;
