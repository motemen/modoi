package Modoi::Plugin::Filter::Response::Store;
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

    return if $res->is_error;
    $context->downloader->store($res->request->uri, $res->content);
}

1;
