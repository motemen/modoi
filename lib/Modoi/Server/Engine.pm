package Modoi::Server::Engine;
use strict;
use warnings;
use base qw(Class::Data::Inheritable Class::Accessor::Fast);
use Template;
use JSON::Syck;
use YAML;
use HTTP::Engine::Response;
use Class::Inspector;
use FindBin;
use Modoi;

__PACKAGE__->mk_classdata(default_view => 'html');

__PACKAGE__->mk_accessors(qw(view segments request));

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    $args->{view} ||= $class->default_view;
    $class->SUPER::new($args);
}

sub _handle {
    my ($self, $req) = @_;
    $self->request($req);
    my $result = $self->handle($req);
    my $render_method = 'render_' . $self->view;
    $self->$render_method($result);
}

sub template {
    my $self = shift;

    my @segments = @{$self->segments};
    shift @segments;
    @segments = ('index') unless @segments;
    $segments[-1] .= '.tt';

    Modoi->context->server->template_dir->file(@segments)->stringify,
}

sub name {
    my $self = shift;
    my $class = ref $self || $self;
    $class =~ s/^Modoi::Server::Engine:://;
    $class;
}

sub path {
    my $self = shift;
    my $name = $self->name;
    $name =~ s/Index$//;
    $name =~ s'::'/'g;
    lc "/$name";
}

sub engines {
    map { bless \my $e, $_ } grep { not /::SUPER$/ } @{Class::Inspector->subclasses(__PACKAGE__)};
}

sub render_html {
    my ($self, $object) = @_;
    $object = {} unless ref $object;
    $object->{modoi} = Modoi->context;
    $object->{engine} = $self;

    my $tt = Template->new({
        INCLUDE_PATH => [ Modoi->context->server->template_dir, $FindBin::Bin ],
        ABSOLUTE => 1,
        PERL => 1,
    });

    $tt->process($self->template, $object, \my $output) or die $tt->error;

    my $res = HTTP::Engine::Response->new;
    $res->body($output);
    $res;
}

sub render_txt {
    my ($self, $object) = @_;
    my $res = HTTP::Engine::Response->new;
    $res->body($object->{_text});
    $res->body(YAML::Dump($object)) unless defined $res->body;
    $res->content_type('text/plain');
    $res;
}

sub render_json {
    my ($self, $object) = @_;
    my $res = HTTP::Engine::Response->new;
    $res->body(JSON::Syck::Dump($object));
    $res->content_type('application/json');
    $res;
}

1;
