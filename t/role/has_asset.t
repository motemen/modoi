use strict;
use Test::More tests => 5;
use t::TestModoi;

package Modoi::TestExtractor;
use Any::Moose;

with 'Modoi::Role::HasAsset';

sub asset_name { 'extractor' }

package Modoi::TestParser;
use Any::Moose;

with 'Modoi::Role::HasAsset';

sub asset_name { 'parser' }
sub asset_module_uses { 'Web::Scraper' }

package main;

use_ok 'Modoi::Role::HasAsset';

my %res = (
    index  => fake_http(GET => 'http://img.2chan.net/b/'),
    thread => fake_http(GET => 'http://img.2chan.net/b/res/69762910.htm'),
);

is_deeply [
    sort Modoi::TestExtractor->new->asset_files($res{index}, 'yaml')
], [
    'assets/2chan.net/extractor.yaml'
];

is_deeply [
    sort Modoi::TestParser->new->asset_files($res{index}, 'pl')
], [
#   'assets/2chan.net/parser.index.pl',
#   'assets/2chan.net/parser.thread.pl',
];

is +Modoi::TestParser->new->load_asset_module($res{index}),
   undef; # 'Modoi::Asset::Module::2chan_net_parser_index';

is +Modoi::TestParser->new->load_asset_module($res{thread}),
   undef; # 'Modoi::Asset::Module::2chan_net_parser_thread';
