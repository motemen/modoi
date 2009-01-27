use DateTime;

sub build_scraper {
    scraper {
        process '//form/a/img', thumbnail => '@src';
        process '//form/blockquote', summary => 'TEXT';
        process '//form/span[@class="postername"]/following-sibling::text()[1]', datetime => [
            TEXT => sub {
                my %dt; @dt{qw(month day year hour minute)} = $_ =~ m"(\d+)/(\d+)/(\d+).*?(\d+):(\d+)";
                $dt{year} += 2000;
                DateTime->new(%dt);
            }
        ];
        process '//form//blockquote', 'bodies[]' => 'TEXT';
    };
}
