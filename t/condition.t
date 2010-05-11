use t::Modoi;
use HTTP::Request::Common;

use_ok 'Modoi::Condition';

my $cond = new_ok 'Modoi::Condition', [ host => '*.2chan.net' ];

isa_ok $cond->host, 'Regexp';
ng     defined $cond->content_type;

ok $cond->pass(GET 'http://img.2chan.net/b/');
ng $cond->pass(GET 'http://www.example.com/');

ok Modoi::Condition::_seems_like_regexp('^/foo/bar/.+\.zip');
ng Modoi::Condition::_seems_like_regexp('image/*');

done_testing;
