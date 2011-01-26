use inc::Module::Install;

name 'Modoi';
license 'perl';

all_from 'lib/Modoi.pm';

requires 'Mouse';
requires 'MouseX::Types::Path::Class';

requires 'Plack';
requires 'Plack::App::Proxy';
requires 'Twiggy';
requires 'Router::Simple';

requires 'Teng';

requires 'Text::Xslate';
requires 'HTML::Entities';

requires 'AnyEvent';
requires 'Coro';
requires 'Coro::LWP';

requires 'LWPx::ParanoidAgent';
requires 'YAML::Syck';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'HTTP::Config';
requires 'Path::Class';
requires 'Script::State';
requires 'Try::Tiny';
requires 'UNIVERSAL::require';
requires 'Data::Dumper';
requires 'parent';

recommends 'Search::Estraier';

build_requires 'Test::More';
build_requires 'Test::TCP';

WriteAll;
