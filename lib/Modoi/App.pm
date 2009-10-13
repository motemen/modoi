package Modoi::App;
use Any::Moose;

use Exporter::Lite;
use UNIVERSAL::require;

our @EXPORT = qw(app);

no Any::Moose;

__PACKAGE__->meta->make_immutable;

sub app {
    my $module = join '::', __PACKAGE__, @_;
    $module->require or warn $@ and return;
    $module;
}

1;
