use strict;
use warnings;

sub should_cache {
    my $res = shift;

    # Return undef to notify fetcher not to cache
    return if ($res->content || '') =~ /The requested URI was not found on this server!/;

    1;
}

sub filter_response {
    my $res = shift;

    if (($res->content || '') =~ /The requested URI was not found on this server!/) {
        $res->http_status(404);
        $res->http_response->code(404);
    }
}
