package Modoi::Plugin::Filter::Fetcher::Store;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Regexp::Assemble;

sub init {
    my ($self, $context) = @_;

    my $regexp = $self->config->{regexp};
    my $ra = Regexp::Assemble->new;
    foreach (ref $regexp eq 'ARRAY' ? @$regexp : ($regexp)) {
        $ra->add($_);
    }
    $self->{uri_regexp} = $ra->re;

    $context->register_hook(
        $self,
        'fetcher.filter_response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    return if $res->is_error;

    return unless $res->uri =~ $self->{uri_regexp};

    $context->downloader->store($res->uri, $res->content);
}

1;
