package t::TestModoi;
use strict;
use warnings;
use Exporter::Lite;
use Encode::Guess;
use Path::Class;
use HTTP::Response;
use HTTP::Request::Common;
use YAML;

our @EXPORT_OK = qw(
    test_file
    fake_http
    http_response_from_file
    yaml
);

our @EXPORT = @EXPORT_OK;

{
    no warnings 'redefine';

    sub import {
        my $pkg = caller;
        if ($INC{'Test/More.pm'}) {
            binmode Test::More->builder->$_, ':utf8' foreach qw(output failure_output todo_output);
        }
        goto &Exporter::Lite::import;
    }
}

sub test_file {
    file('t/samples', @_);
}

sub http_response_from_file ($;$) {
    my ($file, $req) = @_;

    $file = file($file) unless ref $file;

    my $content = $file->slurp;
    my $enc = guess_encoding($content, qw(shift_jis euc-jp utf-8));
    my $res = HTTP::Response->new(200);
    $res->header(Content_Type => $enc ? 'text/html; charset=' . (ref $enc ? $enc->name : 'utf-8') : 'text/html');
    $res->content($content);
    $res->request($req);
    $res;
}

sub fake_http ($;$);
sub fake_http ($;$) {
    if (@_ == 2) {
        my ($method, $uri) = @_;
        my $req = HTTP::Request::Common->can(uc $method)->($uri);
        return fake_http($req);
    }

    my ($req) = @_;
    my $file = $req->uri;
       $file =~ s<^http://><>;
       $file =~ s</><->g;
    http_response_from_file test_file($file), $req;
}

sub yaml (@) {
    YAML::Dump @_;
}

1;
