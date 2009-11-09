use strict;
use Test::More 'no_plan';
use t::TestModoi;

BEGIN { use_ok 'Modoi::Pages' }

my $pages = Modoi::Pages->new;

is $pages->classify(fake_http GET => 'http://img.2chan.net/b/'), 'index';
is $pages->classify(fake_http GET => 'http://img.2chan.net/b/res/69762910.htm'), 'thread';
