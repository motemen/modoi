package Modoi::Parser;
use Any::Moose;

with 'Modoi::Role::HasAsset';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

use Modoi;

sub asset_name { 'parser' }

sub asset_module_uses { qw(DateTime Web::Scraper) }

sub parse {
    my ($self, $res) = @_;

    Modoi->log(debug => 'parsing ' . $res->base);

    my $module  = $self->load_asset_module($res) or return;
    my $scraper = $module->build_scraper;

    my $result = $scraper->scrape($res) or return;
    return unless %$result;

    $result;
}

1;

__END__

=head1 NAME

Modoi::Parser - スレッドをパーズして有用な情報だけ抜き出す
