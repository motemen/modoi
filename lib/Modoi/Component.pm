package Modoi::Component;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use URI;
use Scalar::Util qw(blessed);
use Path::Class qw(dir);
use File::Find::Rule;

__PACKAGE__->mk_accessors(qw(config));

sub class_id {
    my $self = shift;
    my $pkg = ref $self || $self;
       $pkg =~ s/^Modoi:://;

    join '-', split /::/, $pkg;
}

sub assets_dir {
    my $self = shift;
    my $context = Modoi->context;

    if ($self->config->{assets_path}) {
        return $self->config->{assets_path};
    }

    my $assets_base = dir($context->config->{assets_path} || ($FindBin::Bin, 'assets'));
    $assets_base->subdir('core', $self->class_id);
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

    my @host_segments = split /\./, $uri->host;
    my @path_segments = $uri->path_segments;
    while (@host_segments > 2) {
        if (@path_segments) {
            pop @path_segments;
        } else {
            shift @host_segments;
        }

        my $dir = $self->assets_dir->subdir(join '.', @host_segments)->subdir(@path_segments);
        next unless -d $dir;

        foreach my $file ($rule->in($dir)) {
            my $base = File::Basename::basename($file);
            $callback->($file, $base);
        }
    }
}

1;
