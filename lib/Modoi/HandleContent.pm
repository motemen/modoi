package Modoi::HandleContent;
use strict;
use warnings;

sub handle {
    my ($class, $res) = @_;
    foreach (Modoi->context->plugins('HandleContent')) {
        $_->filter($res);
    }
}

1;
