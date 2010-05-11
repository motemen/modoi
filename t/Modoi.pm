package t::Modoi;
use strict;
use warnings;
use lib glob 'modules/*/lib';
use Test::More;
use Exporter::Lite;

our @EXPORT_OK = qw(
    test_file
    fake_http
    http_response_from_file
    yaml
    ng
);

our @EXPORT = @EXPORT_OK;

{
    no warnings 'redefine';

    sub import {
        my $pkg = caller;
        strict->import;
        warnings->import;
        eval qq{
            package $pkg;
            use Test::More;
        };
        binmode +Test::More->builder->$_, ':utf8' foreach qw(output failure_output todo_output);
        goto &Exporter::Lite::import;
    }
}

sub test_file {
    require Path::Class;
    Path::Class::file('t/samples', @_);
}

sub http_response_from_file ($;$) {
    my ($file, $req) = @_;

    require Path::Class;
    $file = Path::Class::file($file) unless ref $file;

    require Encode::Guess;
    require HTTP::Response;

    my $content = $file->slurp;
    my $enc = Encode::Guess::guess_encoding($content, qw(shift_jis euc-jp utf-8));
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
        require HTTP::Request::Common;
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
    require YAML;
    YAML::Dump(@_);
}

sub ng ($;$) {
    require Test::More;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    Test::More::ok !$_[0], $_[1];
}

1;
