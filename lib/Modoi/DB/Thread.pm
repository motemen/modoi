package Modoi::DB::Thread;
use strict;
use warnings;
use base 'Modoi::DB::Object';

__PACKAGE__->meta->setup(
    table => 'thread',
    auto  => 1,
);

__PACKAGE__->meta->column('updated_on')->add_trigger(
    on_save => sub {
        my $self = shift;
        $self->updated_on($self->created_on) unless $self->updated_on;
    }
);

package Modoi::DB::Thread::Manager;
use base 'Rose::DB::Object::Manager';

sub object_class { 'Modoi::DB::Thread' }

__PACKAGE__->make_manager_methods('threads');

1;
