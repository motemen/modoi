use inc::Module::Install;

name 'Modoi';

license 'perl';

build_requires 'Test::More';
build_requires 'HTTP::Engine';
build_requires 'Class::Accessor::Fast';
build_requires 'Class::Data::Inheritable';
build_requires 'Path::Class';
build_requires 'URI::Fetch';
build_requires 'Compress::Zlib';
build_requires 'Exporter::Lite';
build_requires 'Getopt::Long';
build_requires 'YAML';
build_requires 'MIME::Base64';
build_requires 'Template';
build_requires 'Template::Plugin::Filter::VisualTruncate';
build_requires 'JSON::Syck';
build_requires 'Module::Reload';
build_requires 'Rose::DB';
build_requires 'Rose::DB::Object';
build_requires 'HTML::TreeBuilder::XPath';

tests 't/*.t t/*/*.t t/*/*/*.t';

WriteAll;
