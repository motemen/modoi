#!perl
use strict;
use warnings;

use lib 'lib';
use lib glob 'modules/*/lib';

use Modoi 'CLI::Server';

Modoi::CLI::Server->new_with_options;

__END__

=head1 NAME

modoi.psgi

=head1 SYNOPSIS

plackup modoi.psgi -p 3128 -s AnyEvent::HTTPD
