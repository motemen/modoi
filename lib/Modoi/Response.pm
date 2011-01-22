package Modoi::Response;
use strict;
use warnings;
use parent 'Plack::Response';
use Plack::Util::Accessor qw(_original_http_response);

1;
