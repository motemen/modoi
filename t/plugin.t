use strict;
use warnings;
use Test::More tests => 3;
use Modoi;
use Modoi::Plugin;

Modoi->new(config => { assets_path => 'assets' });

my $plugin = Modoi::Plugin::Test->new;

isa_ok $plugin->assets_dir, 'Path::Class::Dir';
is $plugin->assets_dir, 'assets/plugins/Test';
is $plugin->assets_dir_for('http://www.example.com/foo/bar'), 'assets/plugins/Test/www.example.com';

package Modoi::Plugin::Test;
use base qw(Modoi::Plugin);
