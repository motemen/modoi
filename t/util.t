use Test::More tests => 3;
use Modoi::Util;

isa_ok Modoi::Util::absolutize('path'), 'Path::Class::File';
isa_ok Modoi::Util::absolutize(file => 'path'), 'Path::Class::File';
isa_ok Modoi::Util::absolutize(dir  => 'path'), 'Path::Class::Dir';
