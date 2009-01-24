package Modoi::DB::Thread;
use strict;
use warnings;
use base qw(Rose::DB::Object);
use Modoi::DB;

__PACKAGE__->meta->setup(
    table   => 'thread',
    columns => [
        uri           => { type => 'VARCHAR', length => 1024, primary_key => 1 },
        thumbnail_uri => { type => 'VARCHAR', length => 1024 },
        summary       => { type => 'VARCHAR', length => 1024 },
        datetime      => { type => 'DATETIME', not_null => 1 },
    ],
);

sub init_db { Modoi::DB->new }

__PACKAGE__->meta->make_manager_class('threads');

1;
