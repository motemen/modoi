package t::TestModoi;
use strict;
use warnings;
use Test::More;
use Modoi;

sub import {
    strict->import;

    # not to break running application
    Modoi->config->config_file('t/config.yaml');

    my $pkg = caller;
    eval qq{
        package $pkg;
        use Test::More;
    };
    die $@ if $@;
}

1;
