use inc::Module::Install;

name 'Madoi';
license 'perl';

build_requires 'Test::More';
build_requires 'HTTP::Proxy';
build_requires 'Class::Accessor::Fast';
build_requires 'Path::Class';
build_requires 'Exporter::Lite';
build_requires 'Getopt::Long';
build_requires 'YAML';

WriteAll;
