package Modoi;
use strict;
use warnings;
use Modoi::Logger;

sub log {
    my ($class, $level, $message) = @_;
    our $Logger ||= Modoi::Logger->new;
    my $pkg = caller;
    $pkg = $pkg->logger_name if $pkg->can('logger_name');
    $Logger->log($level, "[$level] $pkg $message");
}

1;
