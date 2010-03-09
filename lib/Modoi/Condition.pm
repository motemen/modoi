package Modoi::Condition;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

subtype 'Modoi::Types::Condition::Regexp'
    => as 'RegexpRef';

coerce 'Modoi::Types::Condition::Regexp'
    => from 'Str',
    => via \&make_regexp;

has 'host', (
    is  => 'rw',
    isa => 'Modoi::Types::Condition::Regexp',
    coerce => 1,
    from_uri => 1,
);

has 'path', (
    is  => 'rw',
    isa => 'Modoi::Types::Condition::Regexp',
    coerce => 1,
    from_uri => 1,
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

    foreach my $attr ($self->meta->get_all_attributes) {
        my $name = $attr->name;
        my $regexp = $self->$name or next;
        my $value = _message_attr($message, $attr);
        $value = '' unless defined $value;
        return unless $value =~ $regexp;
    }

    1;
}

sub _message_attr {
    my ($message, $attr) = @_;
    my $name = $attr->name;

    if ($attr->{from_uri}) {
        my $uri = $message->isa('HTTP::Response')
            ? $message->request && $message->request->uri
            : $message->uri;
        $uri && $uri->can($name) && $uri->$name;
    } else {
        $message->$name;
    }
}

sub make_regexp {
    my $pattern = shift;
    return qr/$pattern/ if _seems_like_regexp($pattern);
    $pattern =~ s/\./\\./g;
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
