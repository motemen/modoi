package Modoi::Server::Engine::Index;
use strict;
use warnings;
use base qw(Modoi::Server::Engine);
use Modoi::DB::Thread;

sub handle {
    my ($self, $req) = @_;
    my $page = $req->param('page') || 1;
    +{ threads => Modoi::DB::Thread::Manager->get_threads(sort_by => 'datetime DESC', limit => 50, offset => 50 * ($page - 1)) };
}

1;
