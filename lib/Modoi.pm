package Modoi;
use strict;
use warnings;
use Modoi::Logger;

our $Condvar;

sub log {
    my ($class, $level, $message) = @_;
    our $Logger ||= Modoi::Logger->new;
    my $pkg = caller;
    $Logger->log($level, "[$level] $pkg $message");
}

sub condvar {
    my $class = shift;
    $Condvar = $_[0] if @_;
    $Condvar;
}

1;
