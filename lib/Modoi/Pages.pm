package Modoi::Pages;
use Any::Moose;

with 'Modoi::Role::HasAsset';

no Any::Moose;

__PACKAGE__->meta->make_immutable;

use Modoi::Condition;

sub asset_name { 'pages' }

sub classify {
    my ($self, $res) = @_;

    my $pages = $self->load_asset_yaml($res) or return;
    foreach (@$pages) {
        my $cond = Modoi::Condition->new($_);
        if ($cond->pass($res)) {
            return $_->{name};
        }
    }
}

1;

