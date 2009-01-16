#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Path::Class;
use Getopt::Long;
use YAML;

use lib dir($FindBin::Bin, 'lib')->stringify;
use Madoi;

my $config = file($FindBin::Bin, 'config.yaml');
GetOptions('--config=s', \$config);
Getopt::Long::Configure('bundling'); # allows -c -v

Madoi->bootstrap(config => YAML::LoadFile($config));
