package Modoi::Plugin::Response::InsertScript;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Modoi;

sub filter {
    my ($self, $res) = @_;
    return unless $res->code == 200;
    my $host = Modoi->context->server->config->{name} . ':' . Modoi->context->server->config->{engine}->{port};
    my $content = $res->content;
       $content =~ s!(?=</head>)!<script src="http://$host/static/jquery-1.3.min.js"></script>!i;
    $res->content($content);
}

1;
