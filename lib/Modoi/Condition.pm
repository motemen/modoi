package Modoi::Condition;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

subtype 'Modoi::Types::Condition::Regexp'
    => as 'RegexpRef';

coerce 'Modoi::Types::Condition::Regexp'
    => from 'Str',
    => via \&_make_regexp;

has 'host', (
    is  => 'rw',
    isa => 'Modoi::Types::Condition::Regexp',
    coerce => 1,
);

has 'path', (
    is  => 'rw',
    isa => 'Modoi::Types::Condition::Regexp',
    coerce => 1,
);

has 'content_type', (
    is  => 'rw',
    isa => 'Modoi::Types::Condition::Regexp',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub pass {
    my ($self, $message) = @_;
    # TODO
}

sub _make_regexp {
    my $pattern = shift;
    return qr/$pattern/ if _seems_like_regexp($pattern);
    $pattern =~ s/(?<!\\)\*/.*?/g;
    qr/^$pattern$/;
}

sub _seems_like_regexp {
    my $pattern = shift;
    return 0 unless eval { qr/$pattern/ };
    return 1 if $pattern =~ /^\^|\$$/;     # ex. 2chan.net$
    return 0 if $pattern =~ /\*/;          # ex. image/*
    return 1;
}

1;
