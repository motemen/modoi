package Modoi::Plugin::Filter::Fetcher::Script;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use URI;
use Path::Class qw(file);

__PACKAGE__->mk_accessors('asset_modules');

sub init {
    my $self = shift;
    $self->asset_modules({});
}

sub load_asset_module_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless ref $uri;

    my $host = $uri->host;
    unless (exists $self->asset_modules->{$host}) {
        my $file;
        $self->load_assets_for($uri, '*.pl', sub {
            $file = shift unless $file;
        });

        if ($file) {
            Modoi->context->log(info => "found $file for $uri");
            my $code = file($file)->slurp;
            my $pkg = $host;
               $pkg =~ tr/A-Za-z0-9_/_/c;
               $pkg = __PACKAGE__ . "::$pkg";
            eval qq(
                package $pkg;
                $code;
                1;
            );
            $self->asset_modules->{$host} = $pkg;
        } else {
            $self->asset_modules->{$host} = undef;
        }
    }

    $self->asset_modules->{$host};
}

sub should_cache {
    my ($self, $res) = @_;

    my $module = $self->load_asset_module_for($res->uri) or return 1;
    my $code = $module->can('should_cache') or return 1;
    
    $code->($res);
}

sub filter_response {
    my ($self, $res_ref) = @_;

    my $module = $self->load_asset_module_for($$res_ref->uri) or return;
    my $code = $module->can('filter_response') or return;
    
    $code->($res_ref);
}

1;
