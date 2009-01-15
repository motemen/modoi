package Madoi::Plugin;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(ref $_[0] eq 'HASH' ? $_[0] : { @_ });
       $self->init;
    $self;
}

sub init {
    my $self = shift;
}

1;
