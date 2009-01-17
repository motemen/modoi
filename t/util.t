use Test::More tests => 3;
use Madoi::Util;

isa_ok Madoi::Util::absolutize('path'), 'Path::Class::File';
isa_ok Madoi::Util::absolutize(file => 'path'), 'Path::Class::File';
isa_ok Madoi::Util::absolutize(dir  => 'path'), 'Path::Class::Dir';
