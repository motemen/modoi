package Modoi::Internal;
use Mouse;
use Modoi::Request;
use Modoi::Internal::Engine;
use Router::Simple;

has router => (
    is  => 'rw',
    isa => 'Router::Simple',
    default => sub { Router::Simple->new },
);

sub BUILD {
    my $self = shift;
    $self->router->connect(
        index => '/', {
            handler => Modoi::Internal::Engine->new,
            method  => 'default'
        }
    );
}

# XXX
sub registered_routes {
    my $self = shift;
    return $self->router->{routes};
}

sub registered_simple_routes {
    my $self = shift;
    return [
        grep { $_->pattern !~ /[*:]/ } @{ $self->router->{routes} }
    ];
}

# PSGI env -> Modoi::Response | PSGI res
sub serve {
    my ($self, $env) = @_;

    my $req = Modoi::Request->new($env);
    my $res;

    if (my $m = $self->router->match($env)) {
        my $handler = $m->{handler};
        my $method  = $m->{method};
        $res = $handler->$method($req, $m);
    } else {
        $res = $req->new_response;
        $res->redirect('/');
    }

    return $res;
}

1;
