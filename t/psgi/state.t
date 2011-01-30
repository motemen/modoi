use t::TestModoi;

plan tests => 3;

unlink 't/.modoi.state';

my $app = do 'modoi.psgi';

undef $Modoi::Context::State;
is_deeply +Modoi->context->_state, {}, 'initial state';

{
    package Modoi::Component::t;
    Modoi->package_state->{test} = 1;
}

Modoi->store_state;

ok -e 't/.modoi.state', 'state file created';

undef $Modoi::Context::State;
is_deeply +Modoi->context->_state, {
    'Modoi::Component::t' => { test => 1 }
}, 'state stored';
