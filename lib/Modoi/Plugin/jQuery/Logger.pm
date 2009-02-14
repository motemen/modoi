package Modoi::Plugin::jQuery::Logger;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use JSON::Syck;

sub init {
    my ($self, $context) = @_;

    $context->plugin('jQuery')->require_plugin('jgrowl');

    $context->register_hook(
        $self,
        'server.response' => \&filter_response,
    );

    $context->logger->add(
        Log::Dispatch::Modoi::Plugin::jQuery::Logger->new(
            name      => 'jQuery::Logger',
            owner     => $self,
            min_level => 'notice',
        )
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    foreach (@{$self->{logs} ||= []}) {
        chomp;
        my ($module, $level, $message) = /^([\w:]+) \[(\w+)\] (.+)$/;
        $res->insert_script(
            sprintf q[$(document).ready(function () { setTimeout(function () { $.jGrowl(%s, %s) }, 0) })],
            JSON::Syck::Dump($message),
            JSON::Syck::Dump({ header => "$module", sticky => 1 }),
        );
    }

    $res->add_stylesheet('http://' . $context->server->host_port . '/static/jquery.jgrowl.css'); # TODO

    $self->{logs} = [];
}

package Log::Dispatch::Modoi::Plugin::jQuery::Logger;
use base qw(Log::Dispatch::Output);

sub new {
    my ($class, %args) = @_;
    my $self = bless { owner => $args{owner} }, $class;
    $self->_basic_init(%args);
    $self;
}

sub log_message {
    my ($self, %args) = @_;
    push @{$self->{owner}->{logs}}, $args{message};
}

1;
