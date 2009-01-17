package Madoi::Downloader;
use strict;
use warnings;
use base qw(LWP::UserAgent Class::Accessor::Fast);
use Madoi;
use Madoi::Util;
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

    my $store_dir = dir($config->{store_dir});
    $config->{store_dir} = $store_dir->is_absolute ? $store_dir : Madoi::Util::absolutize(dir => $store_dir);

    $self->config($config);
}

sub store_dir {
    shift->config->{store_dir};
}

sub download {
    my ($self, $uri) = @_;

    Madoi->context->log(debug => "download $uri");

    my $res = $self->get($uri);
    return if $res->is_error;

    $self->store($uri, $res->content);

    1;
}

sub store {
    my ($self, $uri, $content) = @_;

    $uri = URI->new($uri);
    $uri->path($uri->path . 'index.html') if $uri->path =~ qr'/$'; # XXX

    Madoi::Util::ensure_dir my $file = $self->store_dir->file($uri->host, $uri->path_query);

    Madoi->context->log(debug => "store $file");

    my $fh = $file->openw;
    $fh->print($content);
    $fh->close;
}

1;
