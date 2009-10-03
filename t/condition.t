use strict;
use warnings;
use Test::More tests => 7;
use HTTP::Request::Common;

BEGIN { use_ok 'Modoi::Condition' }

my $cond = Modoi::Condition->new(host => '*.2chan.net');

isa_ok $cond->host, 'Regexp';
ok     !defined $cond->content_type;

ok  $cond->pass(GET 'http://img.2chan.net/b/');
ok !$cond->pass(GET 'http://www.example.com/');

ok  Modoi::Condition::_seems_like_regexp('^/foo/bar/.+\.zip');
ok !Modoi::Condition::_seems_like_regexp('image/*');

1;
