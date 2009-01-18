use strict;
use warnings;

my $res = shift;
return if $res->content =~ /The requested URI was not found on this server!/;

1;
