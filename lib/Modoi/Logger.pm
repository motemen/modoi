package Modoi::Logger;
use Any::Moose;
use Log::Dispatch;
use Log::Dispatch::Screen;

has 'logger', (
    is  => 'rw',
    isa => 'Log::Dispatch',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub log {
    my ($self, $level, $message) = @_;
    $self->logger->log(level => $level, message => "$message\n");
}

# TODO
sub _build_logger {
    my $self = shift;
    my $logger = Log::Dispatch->new;
    $logger->add(Log::Dispatch::Screen->new(name => 'screen', min_level => 'debug'));
    $logger;
}

1;
