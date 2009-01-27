package Modoi::Server::Engine::Reload;
use strict;
use warnings;
use base qw(Modoi::Server::Engine);
use Module::Reload;

__PACKAGE__->default_view('txt');

$Module::Reload::Debug = 1;

sub handle {
    my ($self, $req) = @_;

    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= "$_[0]\n" };

    my $result = {
        reloaed => Module::Reload->check
    };

    $result->{_text} = $warn;
    $result;
}

1;
