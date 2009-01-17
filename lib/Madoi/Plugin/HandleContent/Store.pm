package Madoi::Plugin::HandleContent::Store;
use strict;
use warnings;
use base qw(Madoi::Plugin::HandleContent);

sub filter {
    my ($self, $content_ref, $res) = @_;
    return if $res->is_error;
    return unless $$content_ref; # for HTTP::Proxy::BodyFilter::complete
    Madoi->context->downloader->store($res->request->uri, $$content_ref);
}

sub mime_type { '*/*' }

sub will_modify { 0 };

1;
