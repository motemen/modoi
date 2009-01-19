package Modoi::Server::Engine::Reload;
use strict;
use warnings;
use base qw(Modoi::Server::Engine);
use Module::Reload;

__PACKAGE__->default_view('json');

$Module::Reload::Debug = 1;

our @files = keys %INC;

unshift @INC, sub { push @files, $_[1] };

sub handle {
    my ($self, $req) = @_;
    { reloaded => Module::Reload->check };
}

1;
