sub build_scraper {
    scraper {
        process '//form/a/img',      thumbnail_uri => '@src';
        process '//form/blockquote', summary       => 'HTML';
        process '//form/input[@type="checkbox"]/following-sibling::a[starts-with(@href,"mailto:")] | //form/input[@type="checkbox"]/following-sibling::text()[normalize-space(.)][last()]',
            created_on => [
                TEXT => sub {
                    my %dt; @dt{qw(year month day hour minute second)} = m<(\d+)/(\d+)/(\d+).*?(\d+):(\d+):(\d+)>;
                    $dt{year} += 2000;
                    DateTime->new(%dt);
                }
            ];
        process '//form/table[@border="0"][133]//input[@type="checkbox"]/following-sibling::a[starts-with(@href,"mailto:")] | //form/table[@border="0"][last()]//input[@type="checkbox"]/following-sibling::text()[following-sibling::a[@class="del"]][last()]',
            updated_on => [
                TEXT => sub {
                    my %dt; @dt{qw(year month day hour minute second)} = m<(\d+)/(\d+)/(\d+).*?(\d+):(\d+):(\d+)>;
                    $dt{year} += 2000;
                    DateTime->new(%dt);
                }
            ];
        process '//form[@action="futaba.php"]/table', sub { push @{ result->{responses} }, $_->clone };
        result;
    };
}
