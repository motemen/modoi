package Madoi::Plugin;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use URI;
use File::Find::Rule;
use Path::Class qw(dir);
use Scalar::Util qw(blessed);

use Madoi;

__PACKAGE__->mk_accessors(qw(config));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(ref $_[0] eq 'HASH' ? $_[0] : { @_ });
       $self->config({}) unless $self->config;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
}

sub class_id {
    my $self = shift;

    my $pkg = ref($self) || $self;
       $pkg =~ s/Madoi::Plugin:://;
    my @pkg = split /::/, $pkg;

    join '-', @pkg;
}

sub assets_dir {
    my $self = shift;
    my $context = Madoi->context;

    if ($self->config->{assets_path}) {
        return $self->config->{assets_path};
    }

    my $assets_base = dir($context->config->{assets_path} || ($FindBin::Bin, 'assets'));
    $assets_base->subdir('plugins', $self->class_id);
}

sub assets_dir_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless blessed $uri;

    $self->assets_dir->subdir($uri->host);
}

sub load_assets_for {
    my ($self, $uri, $rule, $callback) = @_;

    $uri = URI->new($uri) unless blessed $uri;

    unless (blessed($rule) && $rule->isa('File::Find::Rule')) {
        $rule = File::Find::Rule->name($rule)->extras({ follow => 1 });
    }

    my @segments = $uri->path_segments;
    while (@segments) {
        pop @segments;
        foreach my $file ($rule->in($self->assets_dir_for($uri)->subdir(@segments))) {
            my $base = File::Basename::basename($file);
            $callback->($file, $base);
        }
    }
}

1;
