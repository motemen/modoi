package Modoi::Plugin::JavaScript::AutoReload;
use strict;
use warnings;

sub init {
    my ($self, $context) = @_;
    $context->server->use_jquery;
}

1;
