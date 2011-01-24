use strict;
use Test::More tests => 2;

use_ok 'Modoi::Internal::Engine';

my $tx = Modoi::Internal::Engine->tx;
isa_ok $tx, 'Text::Xslate';
