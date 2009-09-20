use inc::Module::Install;

name 'Modoi';
license 'perl';
build_requires 'Test::More';

requires 'Any::Moose';
requires 'AnyEvent';
requires 'Coro';
requires 'HTML::TreeBuilder::XPath';
requires 'HTTP::Engine';
requires 'HTTP::Request::Common';
requires 'HTTP::Response';
requires 'HTTP::Status';
requires 'LWP::UserAgent';
requires 'List::MoreUtils';
requires 'Log::Dispatch';
requires 'Path::Class';
requires 'UNIVERSAL::require';
requires 'URI::Fetch';
requires 'YAML';

requires_any_moose 'X::Getopt';

WriteAll;
