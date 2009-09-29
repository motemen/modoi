sub build_scraper {
    scraper {
        process '//form/a/img',      thumbnail_uri => '@src';
        process '//form/blockquote', summary       => 'TEXT';
        process '//form/input[@type="checkbox"]/following-sibling::node()[1]', created_on => [
            TEXT => sub {
                my %dt; @dt{qw(year month day hour minute second)} = m<(\d+)/(\d+)/(\d+).*?(\d+):(\d+):(\d+)>;
                $dt{year} += 2000;
                DateTime->new(%dt);
            }
        ];
        process '//form//blockquote', 'responses[]' => 'TEXT';
    };
}
