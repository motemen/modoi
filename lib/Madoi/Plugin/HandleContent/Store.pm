package Madoi::Plugin::HandleContent::Store;
use strict;
use warnings;
use base qw(Madoi::Plugin);

sub filter {
    my ($self, $res) = @_;
    return if $res->is_error;
    Madoi->context->downloader->store($res->request->uri, $res->content);
}

1;
