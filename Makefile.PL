use inc::Module::Install;

name 'Modoi';
license 'perl';

requires 'Plack';
requires 'parent';
requires 'LWP::UserAgent';

build_requires 'Test::More';

WriteAll;
