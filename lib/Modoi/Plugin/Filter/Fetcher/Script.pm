package Modoi::Plugin::Filter::Fetcher::Script;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use URI;
use Path::Class qw(file);

__PACKAGE__->mk_accessors('filters');

sub init {
    my $self = shift;
    $self->filters({});
}

sub filter {
    my ($self, $res) = @_;

    my $uri = $res->uri;
    $uri = URI->new($uri) unless ref $uri;

    unless ($self->filters->{$uri->host}) {
        my $file;
        $self->load_assets_for($uri, '*.pl', sub {
            $file = shift unless $file;
        });

        return 1 unless $file; # thru

        Modoi->context->log(info => "found $file for $uri");
        my $code = file($file)->slurp;
        $self->filters->{$uri->host} = eval "sub { $code }";
    }

    return $self->filters->{$uri->host}->($res);
}

1;
