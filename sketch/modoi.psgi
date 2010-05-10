#!perl
use strict;

use lib 'lib';
use lib glob 'modules/*/lib';

use Modoi 'CLI::Server';

$SIG{INT} = sub {
    Modoi->log(info => 'exiting');
    exit 0;
};

sub logger_name { "$0 (pid $$)" }

my $server = Modoi::CLI::Server->new_with_options;

if ($0 eq __FILE__) {
    $server->run;
} else {
    $server;
}

__END__

=head1 NAME

modoi.psgi

=head1 SYNOPSIS

plackup modoi.psgi -p 3128 -s AnyEvent::HTTPD
