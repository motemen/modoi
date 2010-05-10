#!perl
use strict;
use warnings;

use lib 'lib';
use lib glob 'modules/*/lib';

use Modoi 'CLI::Server';

Modoi::CLI::Server->new_with_options;
