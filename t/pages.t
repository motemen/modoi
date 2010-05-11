use strict;
use t::Modoi;

use_ok 'Modoi::Pages';

my $pages = new_ok 'Modoi::Pages';

is $pages->classify(fake_http GET => 'http://img.2chan.net/b/'), 'index';
is $pages->classify(fake_http GET => 'http://img.2chan.net/b/res/69762910.htm'), 'thread';

done_testing;
