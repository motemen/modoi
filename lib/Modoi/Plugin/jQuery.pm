package Modoi::Plugin::jQuery;
use strict;
use warnings;
use base qw(Modoi::Plugin);

sub init {
    my ($self, $context) = @_;

    $context->register_hook(
        $self,
        'server.response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    return unless $res->code == 200;

    my $host = $context->server->host_port;
    my $content = $res->content;
       $content =~ s!(?=</head>)!\n<script type="text/javascript" src="http://$host/static/jquery-1.3.1.min.js"></script>!i;
    foreach (@{$self->config->{plugins} ||= []}) {
       $content =~ s!(?=</head>)!\n<script type="text/javascript" src="http://$host/static/$_"></script>!i;
    }
    $res->content($content);
}

sub require_plugin {
    my $self = shift;
    push @{$self->config->{plugins}}, @_;
}

1;
