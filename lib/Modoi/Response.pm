package Modoi::Response;
use strict;
use warnings;
use base qw(HTTP::Response);

sub insert_script {
    my ($self, $code) = @_;
    $self->{_content} =~ s!(?=</head>)!\n<script type="text/javascript">$code</script>!i;
}

sub add_stylesheet {
    my ($self, $uri) = @_;
    $self->{_content} =~ s!(?=</head>)!\n<link rel="stylesheet" type="text/css" href="$uri">!i;
}

1;
