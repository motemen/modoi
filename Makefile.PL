use inc::Module::Install;

name 'Modoi';
license 'perl';

all_from 'lib/Modoi.pm';

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
requires 'HTTP::Config';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'Try::Tiny';

recommends 'Search::Estraier';

build_requires 'Test::More';
build_requires 'Test::TCP';

WriteAll;
