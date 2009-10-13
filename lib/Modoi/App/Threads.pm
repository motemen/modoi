package Modoi::App::Threads;
use Any::Moose;
use Modoi::DB::Thread;

extends 'Modoi::App';

no Any::Moose;

__PACKAGE__->meta->make_immutable;

sub threads {
    my $self = shift;
    Modoi::DB::Thread::Manager->get_threads(sort_by => 'updated_on DESC');
}

1;
