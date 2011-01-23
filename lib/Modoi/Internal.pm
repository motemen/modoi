package Modoi::Internal;
use Mouse;
use Modoi::Request;
use Router::Simple;
use Text::Xslate;

has router => (
    is  => 'rw',
    isa => 'Router::Simple',
    default => sub { Router::Simple->new },
);

has tx => (
    is  => 'rw',
    isa => 'Text::Xslate',
    default => sub { Text::Xslate->new(path => [ 'root' ]) },
);

sub BUILD {
    my $self = shift;
    $self->router->connect('/', { handler => $self, method => 'default' });
}

sub serve {
    my ($self, $env) = @_;

    my $req = Modoi::Request->new($env);
    my $res;

    if (my $m = $self->router->match($env)) {
        my $handler = $m->{handler};
        my $method  = $m->{method};
        $res = $handler->$method($req);
    } else {
        $res = $req->new_response;
        $res->redirect('/');
    }

    return $res;
}

sub _html {
    return [ 200, [ 'Content-Type' => 'text/html' ], [ @_ ] ];
}

sub default {
    my ($self, $req) = @_;
    return _html $self->tx->render('index.tx', { context => Modoi->_context });
}

1;
