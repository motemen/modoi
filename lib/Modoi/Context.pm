package Modoi::Context;
use Any::Moose;

use Modoi::Logger;

has 'logger', (
    is  => 'rw',
    isa => 'Modoi::Logger',
    default => sub { Modoi::Logger->new },
);

has 'server', (
    is  => 'rw',
    isa => 'Modoi::Server',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub log {
    my ($self, $level, $message) = @_;
    my $pkg = caller;
    $pkg = caller 1 if $pkg eq 'Modoi';
    $pkg = $pkg->logger_name if $pkg->can('logger_name');
    $self->logger->log($level, "[$level] $pkg $message");
}

sub proxy   { shift->server->proxy  }
sub fetcher { shift->proxy->fetcher }
sub watcher { shift->proxy->watcher }

1;
