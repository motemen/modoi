package Modoi::DB::Object;
use strict;
use warnings;
use base 'Rose::DB::Object';
use Modoi::DB;

sub init_db { Modoi::DB->new }

1;
