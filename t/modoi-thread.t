use strict;
use warnings;
use Test::More tests => 5;
use DateTime;

use_ok 'Modoi::DB::Thread';

Modoi::DB::Thread::Manager->delete_threads(all => 1);

{
    my $t = Modoi::DB::Thread->new(
        uri => 'http://www.example.com/',
        datetime => DateTime->now,
    );
    ok $t->save;
}

{
    my $t = Modoi::DB::Thread->new(
        uri => 'http://www.example.com/',
    );
    ok $t->load;
    isa_ok $t->datetime, 'DateTime';
}

{
    my $t = Modoi::DB::Thread->new(
        uri => 'no-such-uri',
    );
    ok not eval { $t->load };
}
