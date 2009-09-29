package Modoi;
use strict;
use warnings;
use Modoi::Context;

# XXX このパッケージなんなの…

sub context { our $Context ||= Modoi::Context->new }

sub log {
    my $class = shift;
    $class->context->log(@_);
}

1;
