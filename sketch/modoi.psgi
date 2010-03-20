#!perl
use strict;
use warnings;

use YAML;

use lib 'lib';
use lib glob 'modules/*/lib';

use Modoi::Config;
use Modoi::Server;

Modoi::Config->initialize(YAML::LoadFile 'config.yaml');
Modoi::Server->new(use_plack => 1)->as_psgi_app;
