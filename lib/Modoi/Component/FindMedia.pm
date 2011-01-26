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

sub _default_rules {
    return [
        { regexp => qr/(fu\d+\.\w+)\b/, rewrite => 'http://dec.2chan.net/up2/src/$1' },
        { regexp => qr/(f\d+\.\w+)\b/,  rewrite => 'http://dec.2chan.net/up/src/$1'  },
    ];
}

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
}

sub find_media {
    my ($self, $res, $url) = @_;

    return unless $res->code eq '200';

    my $parsed = Modoi->component('ParseHTML')->parse($res, $url) or return;

    return unless $parsed->isa('WWW::Futaba::Parser::Result::Thread');

    # XXX ここ遅そうだな〜
    my @media;
    my @texts = ( $parsed->body, $parsed->head->{mail} );
    push @media, $parsed->image_url if $parsed->image_url;
    foreach my $post ($parsed->posts) {
        push @media, $post->image_url if $post->image_url;
        push @texts, $post->body, $post->head->{mail};
    }
    my $text = join '', grep { defined } @texts;
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
    Modoi->log(debug => 'found media:', @media ? @media : '(none)');
    return @media;
};

1;
