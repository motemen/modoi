package Modoi::Plugin::jQuery::AutoReload;
use strict;
use warnings;
use base qw(Modoi::Plugin);

sub init {
    my ($self, $context) = @_;

    $context->plugin('jQuery')->require_plugin('timer');

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

    $res->insert_script('$.timer(10 * 60 * 1000, function () { location.reload() })');
}

1;
