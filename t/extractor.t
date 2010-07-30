use t::Modoi;

plan tests => 3;

use_ok 'Modoi::Extractor';

my $extractor = new_ok 'Modoi::Extractor';

my $res = fake_http GET => 'http://img.2chan.net/b/res/69762910.htm';
my @extracted = $extractor->extract($res);
is_deeply \@extracted, [qw[
    http://www.nijibox5.com/futabafiles/tubu/src/su232756.jpg
    http://www.nijibox5.com/futabafiles/tubu/src/su232759.jpg
    http://feb.2chan.net/img/b/thumb/1253268691967s.jpg
    http://feb.2chan.net/img/b/src/1253268691967.jpg
]];

done_testing;
