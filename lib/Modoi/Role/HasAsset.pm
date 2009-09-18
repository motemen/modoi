package Modoi::Role::HasAsset;
use Any::Moose '::Role';

use YAML;
use Path::Class 'dir';

requires 'asset_name';

our $Root = dir('assets'); # TODO

sub asset_file {
    my ($self, $res, $ext) = @_;
    my @parts = split /\./, $res->request->uri->host;
    while (@parts) {
        my $file = $Root->file(join('.', @parts), $self->asset_name . ".$ext");
        return $file if -r $file;
        shift @parts;
    }
}

sub load_asset_yaml {
    my ($self, $res) = @_;
    my $file = $self->asset_file($res, 'yaml') or return;
    YAML::LoadFile $file;
}

1;
