package Modoi;
use strict;
use warnings;
use 5.8.8;

our $VERSION = '0.01';

sub log {
    my ($self, $level, @msgs) = @_;
    printf STDERR "[%5s] @msgs\n", $level;
}

sub initialize { __PACKAGE__->_context }
sub _context { our $Modoi ||= Modoi::Context->new }

foreach my $attr (qw(proxy fetcher)) {
    no strict 'refs';
    *$attr = sub { __PACKAGE__->_context->$attr };
}

package Modoi::Context;
use Mouse;
use Modoi::Proxy;

has proxy => (
    is  => 'rw',
    isa => 'Modoi::Proxy',
    default => sub { Modoi::Proxy->new },
    handles => [ 'fetcher' ],
);

1;
