use inc::Module::Install;

name 'Modoi';
license 'perl';

requires 'Any::Moose';
requires 'AnyEvent';
requires 'Coro';
requires 'Plack';

requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'HTML::TreeBuilder::XPath';
requires 'HTTP::Request::Common';
requires 'HTTP::Response';
requires 'HTTP::Status';
requires 'LWP::UserAgent';
requires 'List::MoreUtils';
requires 'Log::Dispatch::Config';
requires 'Path::Class';
requires 'UNIVERSAL::require';
requires 'URI::Fetch';
requires 'YAML';

requires_any_moose 'X::Getopt::Strict';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::TCP';
test_requires 'HTTP::Server::Simple::CGI';

WriteAll;
