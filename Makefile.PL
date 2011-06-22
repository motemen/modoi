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
requires 'DBD::SQLite';

requires 'Text::Xslate';
requires 'HTML::Entities';

requires 'AnyEvent';
requires 'Coro';
requires 'Coro::LWP';

requires 'Data::Dumper';
requires 'Data::Page';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'HTTP::Config';
requires 'LWPx::ParanoidAgent';
requires 'Path::Class';
requires 'Try::Tiny';
requires 'UNIVERSAL::require';
requires 'URI::Escape';
requires 'YAML::Syck';
requires 'parent';

recommends 'Search::Estraier';

build_requires 'Test::More';
build_requires 'Test::TCP', '1.00';
build_requires 'Exporter::Lite';
build_requires 'Carp';
build_requires 'HTTP::Request::Common';

WriteAll;
