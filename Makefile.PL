use inc::Module::Install;

name 'Modoi';
license 'perl';

requires 'Plack';
requires 'parent';
requires 'LWP::UserAgent';
requires 'UNIVERSAL::require';
requires 'Path::Class';

requires 'Mouse';
requires 'MouseX::Types::Path::Class';

build_requires 'Test::More';

WriteAll;
