use strict;
use warnings;
use Test::More tests => 2;

use HTTP::Response;
use HTTP::Status;
use HTTP::Request::Common;
use Path::Class qw(file);

BEGIN { use_ok 'Modoi::Extractor' }

my $extractor = Modoi::Extractor->new;

my $res = HTTP::Response->new(
    RC_OK, status_message(RC_OK),
    [ Content_Type => 'text/html' ],
    scalar file('t/samples/img.2chan.net-b-res-69762910.htm')->slurp,
);
$res->request(GET 'http://img.2chan.net/b/res/69762910.htm');

my @extracted = $extractor->extract($res);
is_deeply \@extracted, [qw[
    http://www.nijibox5.com/futabafiles/tubu/src/su232756.jpg
    http://www.nijibox5.com/futabafiles/tubu/src/su232759.jpg
    http://feb.2chan.net/img/b/thumb/1253268691967s.jpg
    http://feb.2chan.net/img/b/src/1253268691967.jpg
]];
