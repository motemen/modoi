use DateTime;

sub build_scraper {
    scraper {
        process '//form/a/img', thumbnail => '@src';
        process '//form/blockquote', summary => 'TEXT';
        process '//form/text()[contains(.,"/")][1]', datetime => [
            TEXT => sub {
                my %dt; @dt{qw(year month day hour minute second)} = $_ =~ m"(\d+)/(\d+)/(\d+).*?(\d+):(\d+):(\d+)";
                $dt{year} += 2000;
                DateTime->new(%dt);
            }
        ];
        process '//form//blockquote', 'bodies[]' => 'TEXT';
    };
}
