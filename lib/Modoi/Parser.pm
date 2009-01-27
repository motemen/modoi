package Modoi::Parser;
use strict;
use warnings;
use base qw(Modoi::Component);
use YAML;
use DateTime;
use HTML::TreeBuilder::XPath;
use Modoi;

__PACKAGE__->mk_accessors(qw(config parse_rule));

sub new {
    my ($class, %args) = @_;
    my $config = delete $args{config};
    my $self = $class->SUPER::new(%args);
    $self->init_config($config);
    $self;
}

sub init_config {
    my ($self, $config) = @_;
    $self->parse_rule({});
    $self->config($config || {});
}

# TODO
sub parse_response {
    my ($self, $res) = @_;

    my $builder = $self->scraper_builder_for($res->request->uri) or return;
    my $scraper = $builder->build_scraper;
    my $result = $scraper->scrape($res->decoded_content);
    if (not exists $result->{body} and ref $result->{bodies} eq 'ARRAY') {
        $result->{body} = join "\n", @{$result->{bodies}};
    }
    $result->{uri} = $res->request->uri;
    $result;
}

sub scraper_builder_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless ref $uri;
    
    unless (exists $self->{scraper}->{$uri->host}) {
        my $file;
        $self->load_assets_for($uri, 'scraper.pl', sub {
            $file = shift unless $file;
        });

        if ($file) {
            $self->{scraper}->{$uri->host} = $self->load_asset_module($file, $uri);
        } else {
            $self->{scraper}->{$uri->host} = undef;
        }
    }

    $self->{scraper}->{$uri->host};
}

sub asset_code_pre { 'use Web::Scraper' }

1;
