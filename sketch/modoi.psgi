#!perl
use strict;
use warnings;

use lib 'lib';
use lib glob 'modules/*/lib';

use Modoi qw(Config Server);

Modoi::Config->initialize_by_file('config.yaml');
Modoi::Server->new(use_plack => 1)->as_psgi_app;
