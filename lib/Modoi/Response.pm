package Modoi::Response;
use strict;
use warnings;
use base qw(HTTP::Response);

sub insert_script {
    my ($self, $code) = @_;
    $self->{_content} =~ s!(?=</head>)!\n<script type="text/javascript">$code</script>!i;
}

1;
