package Madoi::HandleContent;
use strict;
use warnings;

sub handle {
    my ($class, $res) = @_;
    foreach (Madoi->context->plugins('HandleContent')) {
        $_->filter($res);
    }
}

1;
