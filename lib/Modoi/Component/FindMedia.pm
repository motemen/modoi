package Modoi::Component::FindMedia;
use Mouse;
use Modoi;

extends 'Modoi::Component';

has rules => (
    is  => 'rw',
    isa => 'ArrayRef',
    default => \&_default_rules,
    auto_deref => 1,
);

# { regexp => '(fu\d+\.[a-z]+)', rewrite => 'http://some.host/$1' } みたいに指定する
sub _default_rules {
    return [
    ]
};

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
}

sub find_media {
    my ($self, $res, $url) = @_;

    return unless $res->code eq '200';

    my $parsed = Modoi->component('ParseHTML')->parse($res, $url) or return;

    return unless $parsed->isa('WWW::Futaba::Parser::Result::Thread');

    my @media;
    my @texts = ( $parsed->body, $parsed->head->{mail} );
    push @media, $parsed->image_url if $parsed->image_url;
    foreach my $post ($parsed->posts) {
        push @media, $post->image_url if $post->image_url;
        push @texts, $post->body, $post->head->{mail};
    }
    my $text = join ' ', grep { defined } @texts;
    foreach my $rule ($self->rules) {
        my $regexp  = $rule->{regexp} or next;
        my $rewrite = $rule->{rewrite} or next;
        while ($text =~ /($regexp)/g) {
            my $fragment = $1;
            my @matches = ($fragment, $fragment =~ /$regexp/);
            my $rewrote = $rule->{rewrite};
            $rewrote =~ s/\$(\d+)/$matches[$1]/ge;
            push @media, $rewrote;
        }
    }
    Modoi->log(debug => 'found media:', @media > 10 ? (@media[0..9], 'and', @media - 10, 'more') : @media ? @media : '(none)');
    return @media;
};

1;
