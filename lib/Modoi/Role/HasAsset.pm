package Modoi::Role::HasAsset;
use Any::Moose '::Role';

use YAML;
use Path::Class 'dir';

requires 'asset_name';

our $Root = dir('assets'); # TODO

sub root { $Root }

sub asset_file {
    my ($self, $res, $ext) = @_;
    my @parts = split /\./, $res->request->uri->host;
    while (@parts) {
        my $file = $self->root->file(join('.', @parts), $self->asset_name . ".$ext");
        return $file if -r $file;
        shift @parts;
    }
}

sub load_asset_yaml {
    my ($self, $res) = @_;
    my $file = $self->asset_file($res, 'yaml') or return;
    YAML::LoadFile $file;
}

our %ModuleLoaded;

sub load_asset_module {
    my ($self, $res) = @_;
    my $file = $self->asset_file($res, 'pl') or return;
    my $pkg = $file->relative($self->root)->dir;
       $pkg =~ s/\W/_/g;
       $pkg = "Modoi::Asset::Module::$pkg";

    return $pkg if $ModuleLoaded{$pkg};

    my $code = qq{
        package $pkg;
    };
    if ($self->can('asset_module_uses')) {
        $code .= "use $_;\n" foreach $self->asset_module_uses;
    }
    $code .= $file->slurp;

    eval $code;

    warn $@ and return if $@;

    $ModuleLoaded{$pkg}++;
    $pkg;
}

1;
