package Modoi::Plugin::jQuery::AutoReload;
use strict;
use warnings;
use base qw(Modoi::Plugin);

sub init {
    my ($self, $context) = @_;

    $context->plugin('jQuery')->require_plugin('jquery.timer.js');

    $context->register_hook(
        $self,
        'server.response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    return unless $res->code == 200 && $res->request->uri =~ m'/res/';

    $res->insert_script(<<'__SCRIPT__');
$.timer(3 * 60 * 1000, function () { location.reload() });
__SCRIPT__
}

1;
