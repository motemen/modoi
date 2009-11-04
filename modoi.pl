#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Modoi 'CLI::Server';

$SIG{INT} = sub {
    Modoi->log(info => 'exiting');
    exit 0;
};

sub logger_name { "$0 (pid $$)" }

Modoi::CLI::Server->new_with_options->run;
