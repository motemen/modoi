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

recommends 'Plack::Handler::AnyEvent::HTTPD';

requires_any_moose 'X::Getopt::Strict';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::TCP';
test_requires 'HTTP::Server::Simple::CGI';

WriteAll;

sub MY::install {
    <<__INSTALL__;
install:
	false
__INSTALL__
}

sub MY::postamble {
    <<__POSTAMBLE__;
coverage:
	cover -test -select_re '^blib'
__POSTAMBLE__
}
