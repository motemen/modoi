package Modoi::View::iPhone;
use Any::Moose;

with 'Modoi::Role::HasAsset';

has 'mt', (
    is  => 'rw',
    isa => 'Text::MicroTemplate::File',
    required => 1,
);

no Any::Moose;

__PACKAGE__->meta->make_immutable;

sub asset_name { 'view.iphone' }

sub render {
    my ($self, $page, $content) = @_;
    if (my $manipulate = $self->can("manipulate_$page")) {
        $self->$manipulate($content);
    }
    $self->mt->render_file("iphone/$page.mt", $content)->as_string;
}

sub manipulate_index {
    my ($self, $content) = @_;
    foreach my $elems (@{$content->{threads}}) {
        splice @$elems, 0, 8;
        foreach my $elem (@$elems) {
            if (ref $elem) {
                # スレ先頭の del リンクを削除
                if ($elem->tag eq 'input' ||
                   ($elem->tag eq 'a' && $elem->attr('href') =~ /^javascript:/)) {
                    $elem->detach;
                    $elem->delete;
                    $elem = undef;
                    next;
                }
                # レスの del リンクと広告を削除
                $_->detach && $_->delete foreach (
                    $elem->look_down(_tag => 'a', href => qr/^javascript:/),
                    $elem->look_down(_tag => 'input'),
                    $elem->look_down(_tag => 'td', align => 'right', valign => 'top'),
                );
                # 色を消す
                $_->attr(bgcolor => undef) foreach $elem->look_down(_tag => 'td');
                # 左寄せにしない
                $_->attr(align => undef) foreach $elem->look_down(_tag => 'img');
            }
        }
    }
}

1;

