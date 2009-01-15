package Madoi::HandleContent;
use strict;
use warnings;

sub handle {
    my ($class, $context, $dataref, $message) = @_;
    foreach ($context->plugins('HandleContent')) {
        $_->handle($dataref, $message);
    }
}

1;
