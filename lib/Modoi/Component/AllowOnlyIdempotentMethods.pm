package Modoi::Component::AllowOnlyIdempotentMethods;
use Mouse;

extends 'Modoi::Component';

sub INSTALL {
    my ($self, $context) = @_;
    Modoi::Fetcher::Role::AllowOnlyIdempotentMethods->meta->apply($context->fetcher);
}

package Modoi::Fetcher::Role::AllowOnlyIdempotentMethods;
use Mouse::Role;
use Modoi::Response;

our %IdempotentMethods = (
    HEAD => 1,
    GET => 1,
);

around request => sub {
    my ($orig, $self, $req) = @_;

    unless ($IdempotentMethods{ uc $req->method }) {
        return Modoi::Response->new(405, [ 'Content-Type' => 'text/plain' ], [ 'Method not allowed' ]);
    }

    return $self->$orig($req);
};

1;
