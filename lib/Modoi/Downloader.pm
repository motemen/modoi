package Modoi::Downloader;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Modoi;
use Modoi::Util;
use URI;
use Path::Class qw(dir);

__PACKAGE__->mk_accessors(qw(config));

sub new {
    my ($class, %args) = @_;
    my $config = delete $args{config};
    my $self = $class->SUPER::new(%args);
       $self->init_config($config);
    $self;
}

sub init_config {
    my ($self, $config) = @_;

    $config->{store_dir} ||= '.downloader/store';

    my $store_dir = dir($config->{store_dir});
    $config->{store_dir} = $store_dir->is_absolute ? $store_dir : Modoi::Util::absolutize(dir => $store_dir);

    $self->config($config);
}

sub store_dir {
    shift->config->{store_dir};
}

sub download {
    my ($self, $uri) = @_;

    my $file = $self->file_for_uri($uri);
    if (-e $file) {
        # TODO check Last-Modified or something
        Modoi->context->log(info => "download $uri => file exists");
        return 1;
    }

    my $res = Modoi->context->fetcher->fetch($uri);
    if (!$res->is_error) {
        Modoi->context->log(info => "download $uri => failed");
        return;
    }

    Modoi->context->log(info => "download $uri => $file");
    $self->store($uri, $res->content);
    1;
}

sub store {
    my ($self, $uri, $content) = @_;

    Modoi::Util::ensure_dir my $file = $self->file_for_uri($uri);

    my $fh = $file->openw;
    $fh->print($content);
    $fh->close;
}

sub file_for_uri {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless ref $uri;
    $uri->path($uri->path . 'index.html') if $uri->path =~ qr'/$'; # XXX

    $self->store_dir->file($uri->host, $uri->path_query);
}

1;
