package Modoi::Util::HTTP;
use strict;
use warnings;
use Exporter::Lite;

our @EXPORT = ();

our @EXPORT_OK = qw(
    should_serve_content
    may_return_not_modified
    may_serve_cache
);

sub should_serve_content {
    my $req = shift;
    !_may_serve_cache($req) && !_may_return_not_modified($req);
}

sub may_return_not_modified {
    my $req = shift;
    $req->header('If-None-Match') || $req->header('If-Modified-Since');
}

sub may_serve_cache {
    my $req = shift;
    ($req->header('Pragma')        || '') ne 'no-cache' &&
    ($req->header('Cache-Control') || '') ne 'no-cache';
}

1;
