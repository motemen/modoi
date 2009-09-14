#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Modoi::CLI::Server;

Modoi::CLI::Server->new_with_options->run;
