#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Path::Class;

use lib dir($FindBin::Bin, 'lib')->stringify;
use Madoi;

my $config = {
    plugin_path => dir($FindBin::Bin, 'lib', 'Madoi', 'Plugin'),
    plugins => [{
        module => 'HandleContent::Store'
    }],
    server => {
        host => undef,
        port => 3128,
    }
};

Madoi->bootstrap(config => $config);
