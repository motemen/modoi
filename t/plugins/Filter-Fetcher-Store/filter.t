use strict;
use Test::More tests => 3;
use HTTP::Response;
use HTTP::Request::Common;
use Modoi;

my $module = 'Modoi::Plugin::Filter::Fetcher::Store';

use_ok $module;

Modoi->new;

my $plugin = $module->new(config => { regexp => 'example.com' });
like 'http://www.example.com/', $plugin->{uri_regexp};
unlike 'http://www.google.com/', $plugin->{uri_regexp};
