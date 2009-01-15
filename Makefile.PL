use inc::Module::Install;

name 'Madoi';
license 'perl';

build_requires 'Test::More';
build_requires 'HTTP::Proxy';
build_requires 'Class::Accessor::Fast';

WriteAll;
