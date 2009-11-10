package Modoi::Role::HasAsset;
use Any::Moose '::Role';

use Modoi;
use YAML;
use Path::Class;

requires 'asset_name';

our $Root = dir('assets'); # TODO

sub root { $Root }

sub asset_files {
    my ($self, $res, $ext) = @_;

    my @parts = split /\./, $res->request->uri->host;

    while (@parts) {
        my $file = $self->root->file(join('.', @parts), $self->asset_name . ".$ext");
        return $file if -r $file;

        $file =~ s/(\.\Q$ext\E)$/.*$1/;
        if (my @files = glob $file) {
            return map { file($_) } @files;
        }

        shift @parts;
    }

    return;
}

sub load_asset_yaml {
    my ($self, $res) = @_;
    my $file = $self->asset_files($res, 'yaml') or return;
    YAML::LoadFile $file;
}

our %ModuleLoaded;

sub load_asset_module {
    my ($self, $res) = @_;

    my $ext = 'pl';
    if (my $name = Modoi->context->pages->classify($res)) {
        $ext = "$name.$ext";
    }

    my @files = $self->asset_files($res, $ext);
    foreach my $file (@files) {
        my $module = $self->_eval_asset_module($file) or next;
        return $module;
    }
}

sub _eval_asset_module {
    my ($self, $file) = @_;

    $file = file($file) unless ref $file;

    my $pkg = $file->relative($self->root);
       $pkg =~ s/\.pl$//;
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
