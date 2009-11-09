use strict;
use utf8;
use Test::More tests => 19;
use t::TestModoi;

BEGIN { use_ok 'Modoi::Parser' }

my $parser = Modoi::Parser->new;

{
    my $res = fake_http GET => 'http://img.2chan.net/b/res/69762910.htm';
    my $parsed = $parser->parse($res);

    is     $parsed->{summary},  'ｷﾀ━━━━━━(ﾟ∀ﾟ)━━━━━━ !!!!! ';
    isa_ok $parsed->{responses}, 'ARRAY';
    is     scalar @{$parsed->{responses}}, 58;
    isa_ok $parsed->{thumbnail_uri}, 'URI';
    is     $parsed->{thumbnail_uri}, 'http://feb.2chan.net/img/b/thumb/1253268691967s.jpg';
    isa_ok $parsed->{created_on}, 'DateTime';
    is     $parsed->{created_on}->strftime('%F %T'), '2009-09-18 19:11:31';
    isa_ok $parsed->{updated_on}, 'DateTime';
    is     $parsed->{updated_on}->strftime('%F %T'), '2009-09-18 20:00:38';
}

{
    my $res = fake_http GET => 'http://nov.2chan.net/b/res/14133347.htm';
    my $parsed = $parser->parse($res);

    is     $parsed->{summary},  'ねーえ、4期まだぁ？ ';
    isa_ok $parsed->{responses}, 'ARRAY';
    is     scalar @{$parsed->{responses}}, 12;
    isa_ok $parsed->{thumbnail_uri}, 'URI';
    is     $parsed->{thumbnail_uri}, 'http://nov.2chan.net:81/b/thumb/1257217162954s.jpg';
    isa_ok $parsed->{created_on}, 'DateTime';
    is     $parsed->{created_on}->strftime('%F %T'), '2009-11-03 11:59:22';
    isa_ok $parsed->{updated_on}, 'DateTime';
    is     $parsed->{updated_on}->strftime('%F %T'), '2009-11-03 16:31:40';
}

{
    my $res = fake_http GET => 'http://img.2chan.net/b/';
    my $parsed = $parser->parse($res);

    note yaml $parsed;
}
