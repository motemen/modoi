use inc::Module::Install;

name 'Modoi';

license 'perl';

build_requires 'Test::More';
build_requires 'HTTP::Engine';
build_requires 'Class::Accessor::Fast';
build_requires 'Class::Data::Inheritable';
build_requires 'Path::Class';
build_requires 'Exporter::Lite';
build_requires 'Getopt::Long';
build_requires 'YAML';

tests 't/*.t t/*/*.t t/*/*/*.t';

WriteAll;
