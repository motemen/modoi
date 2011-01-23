use inc::Module::Install;

name 'Modoi';
license 'perl';

requires 'Mouse';
requires 'MouseX::Types::Path::Class';

requires 'Plack';
requires 'Plack::App::Proxy';

requires 'Teng';

requires 'Text::Xslate';
requires 'HTML::Entities';

requires 'parent';
requires 'LWP::UserAgent';
requires 'Path::Class';
requires 'UNIVERSAL::require';

build_requires 'Test::More';

WriteAll;
