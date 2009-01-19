package Modoi::Server::Engine;
use strict;
use warnings;
use base qw(Class::Data::Inheritable Class::Accessor::Fast);
use Template;
use JSON::Syck;
use HTTP::Engine::Response;
use FindBin;
use Modoi;

__PACKAGE__->mk_classdata(default_view => 'html');

__PACKAGE__->mk_accessors(qw(view segments));

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    $args->{view} ||= $class->default_view;
    $class->SUPER::new($args);
}

sub _handle {
    my ($self, $req) = @_;
    my $result = $self->handle($req);

    my $render_method = 'render_' . $self->view;
    $self->$render_method($result);
}

sub render_html {
    my ($self, $object) = @_;
    $object = { } unless ref $object;
    $object->{modoi} = Modoi->context;

    my $tt = Template->new({
        INCLUDE_PATH => [ Modoi->context->server->template_dir, $FindBin::Bin ],
        ABSOLUTE => 1,
        PERL => 1,
    });

    my @segments = @{$self->segments};
    shift @segments;

    @segments = ('index') unless @segments;
    $segments[-1] .= '.tt';

    $tt->process(
        Modoi->context->server->template_dir->file(@segments)->stringify,
        $object,
        \my $output,
    ) or die $tt->error;

    my $res = HTTP::Engine::Response->new;
    $res->body($output);
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
