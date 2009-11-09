sub condition {
    +{ path => qr<^/b/$> };
}

sub build_scraper {
    scraper {
        result->{threads} = [];
        process '//form[@action="futaba.php"]', sub {
            my $form = shift;

            foreach ($form->content_list) {
                if (ref && $_->tag eq 'hr') {
                    push @{ result->{threads} }, [];
                    next;
                }

                next if ref && $_->tag eq 'table' && ($_->attr('style') || $_->attr('align'));

                push @{ result->{threads}->[-1] }, $_ if @{ result->{threads} };
            }
        };
        result;
    };
}
