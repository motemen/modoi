#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Path::Class;
use Getopt::Long;
use YAML;

use lib dir($FindBin::Bin, 'lib')->stringify;
use Modoi;

my $config = file($FindBin::Bin, 'config.yaml');
GetOptions('--config=s', \$config);
Getopt::Long::Configure('bundling'); # allows -c -v

Modoi->bootstrap(config => YAML::LoadFile($config));
