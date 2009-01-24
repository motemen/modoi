package Modoi::Parser;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Path::Class qw(dir);
use Scalar::Util qw(blessed);
use File::Find::Rule;
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

# XXX XXX XXX
sub class_id {
    my $self = shift;
    my $pkg = ref $self || $self;
       $pkg =~ s/Modoi:://;

    join '-', split /::/, $pkg;
}

sub assets_dir {
    my $self = shift;
    my $context = Modoi->context;

    if ($self->config->{assets_path}) {
        return $self->config->{assets_path};
    }

    my $assets_base = dir($context->config->{assets_path} || ($FindBin::Bin, 'assets'));
    $assets_base->subdir('core', $self->class_id);
}

sub assets_dir_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless blessed $uri;

    $self->assets_dir->subdir($uri->host);
}

sub load_assets_for {
    my ($self, $uri, $rule, $callback) = @_;

    $uri = URI->new($uri) unless blessed $uri;

    unless (blessed($rule) && $rule->isa('File::Find::Rule')) {
        $rule = File::Find::Rule->name($rule)->extras({ follow => 1 });
    }

    my @segments = $uri->path_segments;
    while (@segments) {
        pop @segments;
        foreach my $file ($rule->in($self->assets_dir_for($uri)->subdir(@segments))) {
            my $base = File::Basename::basename($file);
            $callback->($file, $base);
        }
    }
}

1;
