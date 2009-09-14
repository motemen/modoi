package Modoi;
use strict;
use warnings;
use Modoi::Logger;

sub log {
    my ($class, $level, $message) = @_;
    our $Logger ||= Modoi::Logger->new;
    my $pkg = caller;
    $Logger->log($level, "[$level] $pkg $message");
}

1;
