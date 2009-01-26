use inc::Module::Install;

name 'Modoi';

license 'perl';

requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Compress::Zlib';
requires 'Exporter::Lite';
requires 'Getopt::Long';
requires 'HTML::TreeBuilder::XPath';
requires 'HTTP::Engine';
requires 'JSON::Syck';
requires 'MIME::Base64';
requires 'Module::Reload';
requires 'Path::Class';
requires 'Regexp::Assemble';
requires 'Rose::DB';
requires 'Rose::DB::Object';
requires 'Template';
requires 'Template::Plugin::Filter::VisualTruncate';
requires 'URI::Fetch';
requires 'Web::Scraper';
requires 'YAML';

test_requires 'Test::More';

tests 't/*.t t/*/*.t t/*/*/*.t';

WriteAll;
