package Modoi::Server::Engine::Index;
use strict;
use warnings;
use base qw(Modoi::Server::Engine);
use Modoi::DB::Thread;

sub handle {
    my ($self, $req) = @_;
    +{ threads => Modoi::DB::Thread::Manager->get_threads(sort_by => 'datetime DESC') };
}

1;
