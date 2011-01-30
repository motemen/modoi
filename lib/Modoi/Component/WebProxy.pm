package Modoi::Component::WebProxy;
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
    $config->add(m_domain => '.2chan.net');
    return $config;
}

sub INSTALL {
    my ($self, $context) = @_;
    $context->internal->router->connect(
        proxy => '/http/*', {
            handler => Modoi::Internal::Engine::WebProxy->new,
            method  => 'proxy',
        }
    );
}

package Modoi::Internal::Engine::WebProxy;
use Mouse;
use Modoi;
use URI::Escape qw(uri_unescape);

extends 'Modoi::Internal::Engine';

sub proxy {
    my ($self, $req, $m) = @_;

    my $env = $req->env;
    my $url = $m->{splat}->[0] or die;
    $url .= "?$env->{QUERY_STRING}" if length $env->{QUERY_STRING};

    my $base = $env->{REQUEST_URI};
    substr($base, -length $url) = '';
    $env->{REQUEST_URI} = "http://$url";

    my $res = Modoi->proxy->serve($env);
    my $content_type = $res->content_type;
    if ($content_type =~ m(^text/x?html\b) && $res->code eq '200') {
        my $content = $res->as_http_message->decoded_content;
        # XXX Regexp::Common 使ってると empty response になることがある、謎
        $content =~ s#
            \b(http://[a-zA-Z0-9\-_.!~*'():@&=+\$,]+)
        #
            my $url = $1;
            if (Modoi->component('WebProxy')->condition->matching($url)) {
                $url =~ s<^http://><$base>;
            }
            $url;
        #gex;
        $content =~ s(<meta[^>]+http-equiv="Content-type"[^>]+>)()gi;
        utf8::encode $content;
        $content_type =~ s/(;.+)?$/; charset=utf-8/;

        $res->headers->remove_content_headers;
        $res->content($content);
        $res->content_type($content_type);
        $res->content_length(length $content);
    }
    return $res;
}

1;
