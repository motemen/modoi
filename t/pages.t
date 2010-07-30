use strict;
use t::Modoi;

plan tests => 4;

use_ok 'Modoi::Pages';

my $pages = new_ok 'Modoi::Pages';

is $pages->classify(fake_http GET => 'http://img.2chan.net/b/'), 'index';
is $pages->classify(fake_http GET => 'http://img.2chan.net/b/res/69762910.htm'), 'thread';

done_testing;
