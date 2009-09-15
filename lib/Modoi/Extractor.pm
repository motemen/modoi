package Modoi::Extractor;
use Any::Moose;

use HTML::TreeBuilder::XPath;

__PACKAGE__->meta->make_immutable;

no Any::Moose;

# TODO site specific extractor
sub extract {
    my ($self, $res) = @_;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($res->content);

    my @images = $tree->findnodes_as_string('//img/@src');

    +{ images => \@images };
}

1;
