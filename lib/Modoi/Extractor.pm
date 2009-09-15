package Modoi::Extractor;
use Any::Moose;

use Web::Scraper;

__PACKAGE__->meta->make_immutable;

no Any::Moose;

# TODO site specific extractor
sub extract {
    my ($self, $res) = @_;

    my $scraper = scraper {
        process '//img', 'images[]' => '@src';
    };

    $scraper->scrape($res);
}

1;
