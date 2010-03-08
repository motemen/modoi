package Modoi::Util::HTTP;
use strict;
use warnings;
use Exporter::Lite;
use DateTime;
use DateTime::Format::HTTP;

our @EXPORT = ();

our @EXPORT_OK = qw(
    should_serve_content
    may_return_not_modified
    may_serve_cache
    one_year_from_now
);

sub should_serve_content {
    my $req = shift;
    !may_serve_cache($req) && !may_return_not_modified($req);
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

sub one_year_from_now {
    my $dt = DateTime->now->add(years => 1);
    $dt->set_formatter('DateTime::Format::HTTP');
    $dt;
}

1;
