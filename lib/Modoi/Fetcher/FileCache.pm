package Modoi::Fetcher::FileCache;
use Any::Moose;
use Any::Moose 'X::Types::Path::Class';

use LWP::MediaTypes qw(guess_media_type);

# URI::Fetch とべったりなキャッシュクラス

has 'cache_root', (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

sub _ensure_dir {
    my $path = shift;
    return $path if -e $path;
    _ensure_dir($path->parent) unless -d $path->parent;
    mkdir $path->parent;
    $path;
}

sub cache_entry_file {
    my ($self, $uri) = @_;
    $uri =~ s<^https?://><>; # XXX https?
    $uri =~ s</+></>g;
    $uri =~ s</$></index.html>g; # XXX
    $self->cache_root->file(split qr</>, $uri);
}

sub get {
    my ($self, $uri) = @_;
    Modoi->log(debug => "get cache $uri");
    my $file = $self->cache_entry_file($uri);
    -e $file or return;
    return {
        Content      => scalar $file->slurp,
        LastModified => $file->stat->mtime,
        ContentType  => scalar guess_media_type($uri),
    };
}

sub set {
    my ($self, $uri, $struct) = @_;
    Modoi->log(debug => "set cache $uri");
    my $file = $self->cache_entry_file($uri);
    _ensure_dir $file;
    $file->openw->print($struct->{Content});
    utime time, $struct->{LastModified} || time, $file;

    (my $ct = $struct->{ContentType}) =~ s/;.*//;
    my $guessed_ct = guess_media_type("$file");
    if ($ct ne $guessed_ct) {
        Modoi->log(warning => "Content-Type did not match: $ct != $guessed_ct, $uri");
    }
}

sub uri_fetch_args {
    my $self = shift;
    return (
        Cache  => $self,
        Freeze => sub { $_[0] },
        Thaw   => sub { $_[0] },
    );
}

1;
