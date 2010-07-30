use t::Modoi;

plan tests => 1;

use_ok 'Modoi::Util::HTTP', qw(should_serve_content may_return_not_modified may_serve_cache);

done_testing;
