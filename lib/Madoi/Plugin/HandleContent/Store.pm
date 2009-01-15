package Madoi::Plugin::HandleContent::Store;
use strict;
use warnings;
use base qw(Madoi::Plugin);
use Madoi::Util qw(absolutize ensure_dir);
use Path::Class ();

__PACKAGE__->mk_accessors(qw(dir));

sub init {
    my $self = shift;
    $self->dir(Path::Class::dir(absolutize($self->config->{dir})));
}

sub register {
    my ($self, $context) = @_;
}

sub handle {
    my ($self, $dataref, $response) = @_;
    my $uri = $response->request->uri->clone;
       $uri->path('/index.html') if $uri->path eq '/'; # XXX

    my $file = $self->dir->file($uri->host, $uri->path);
    ensure_dir $file;

    my $fh = $file->openw;
    $fh->print($$dataref);
    $fh->close;
}

1;
