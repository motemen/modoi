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

requires 'AnyEvent';
requires 'parent';
requires 'LWP::UserAgent';
requires 'Path::Class';
requires 'UNIVERSAL::require';
requires 'Script::State';
requires 'DateTime';
requires 'DateTime::Format::HTTP';

build_requires 'Test::More';
build_requires 'Test::TCP';

WriteAll;
