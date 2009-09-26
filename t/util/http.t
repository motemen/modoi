use strict;
use warnings;
use Test::More tests => 1;

use HTTP::Request::Common;

BEGIN { use_ok 'Modoi::Util::HTTP', qw(should_serve_content may_return_not_modified may_serve_cache) }
