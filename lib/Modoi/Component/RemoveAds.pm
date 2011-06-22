package Modoi::Component::RemoveAds;
use Mouse;

extends 'Modoi::Component';

has regexps => (
    is  => 'rw',
    isa => 'ArrayRef[Regexp]',
    default => sub {
        [
            qr(<div style="width:468px;height:60px;">.*$)m,
            qr(<div class="ama">.*?</form></blockquote></div>)sm,
        ]
    },
    auto_deref => 1,
);

has rewrite_to => (
    is  => 'rw',
    isa => 'Str',
    default => '',
);

sub INSTALL {
    my ($self, $context) = @_;
    Modoi::Proxy::Role::Component::RemoveAds->meta->apply($context->proxy);
}

package Modoi::Proxy::Role::Component::RemoveAds;
use Mouse::Role;
use Modoi;

around serve => sub {
    my ($orig, $self, @args) = @_;
    my $res = $self->$orig(@args);

    my $component = Modoi->component('RemoveAds');
    my $rewrite_to = $component->rewrite_to;

    $res->modify_content(sub {
        foreach my $re ($component->regexps) {
            s/$re/$rewrite_to/g;
        }
    });
    return $res;
};

1;
