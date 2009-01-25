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

    my $rule = $self->parse_rule_for($res->request->uri) or return;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($res->decoded_content);
    my $result = {};

    foreach (keys %$rule) {
        my $xpath = $rule->{$_}->{xpath} or next;
        my $nodes = $tree->findnodes($xpath) or next;
        my $node  = $nodes->get_node(0);
        $result->{$_} = $node;
    }

    $result->{thumbnail} = $result->{thumbnail}->attr('src');
    $result->{summary}   = $result->{summary}->as_text;
    my %dt; @dt{split /\s+/, $rule->{datetime}->{capture}} = $result->{datetime}->getValue =~ /$rule->{datetime}->{pattern}/;
    $dt{year} = sprintf '20%02d', $dt{year} if length $dt{year} <= 2;
    $result->{datetime}  = DateTime->new(%dt);

    $result;
}

sub parse_rule_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless ref $uri;
    
    unless (exists $self->parse_rule->{$uri->host}) {
        my $file;
        $self->load_assets_for($uri, '*.yaml', sub {
            $file = shift unless $file;
        });

        if ($file) {
            $self->parse_rule->{$uri->host} = YAML::LoadFile($file);
            Modoi->context->log(info => "found $file for $uri");
        } else {
            $self->parse_rule->{$uri->host} = undef;
        }
    }

    $self->parse_rule->{$uri->host};
}

1;
