package Madoi::Plugin::HandleContent::Store;
use strict;
use warnings;
use base qw(Madoi::Plugin::HandleContent);
use Madoi::Util qw(absolutize ensure_dir);
use Path::Class ();

__PACKAGE__->mk_accessors(qw(dir));

sub init {
    my $self = shift;
    $self->dir(Path::Class::dir(absolutize($self->config->{dir})));
}

sub filter {
    my ($self, $dataref, $response) = @_;
    my $uri = $response->request->uri->clone;
       $uri->path('/index.html') if $uri->path eq '/'; # XXX

    ensure_dir my $file = $self->dir->file($uri->host, $uri->path);

    my $fh = $file->openw;
    $fh->print($$dataref);
    $fh->close;
}

1;
