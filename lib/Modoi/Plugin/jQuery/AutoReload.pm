package Modoi::Plugin::jQuery::AutoReload;
use strict;
use warnings;
use base qw(Modoi::Plugin);

sub init {
    my ($self, $context) = @_;

    $context->plugin('jQuery')->require_plugin('timer');

    $self->config->{interval} ||= 10;

    $context->register_hook(
        $self,
        'server.response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    return unless $res->code == 200 && $res->request->uri =~ m'/res/';
    return if $res->header('X-Modoi-Plugin-ServeCache');

    $res->insert_script(sprintf '$.timer(%d * 60 * 1000, function () { location.reload() })', $self->config->{interval});
}

1;
