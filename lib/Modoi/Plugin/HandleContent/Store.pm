package Modoi::Plugin::HandleContent::Store;
use strict;
use warnings;
use base qw(Modoi::Plugin);

sub filter {
    my ($self, $res) = @_;
    return if $res->is_error;
    Modoi->context->downloader->store($res->request->uri, $res->content);
}

1;
