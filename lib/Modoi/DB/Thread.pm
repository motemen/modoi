package Modoi::DB::Thread;
use strict;
use warnings;
use base 'Modoi::DB::Object';
use WWW::Futaba::Parser;

__PACKAGE__->meta->setup(
    table => 'thread',
    auto  => 1,
);

__PACKAGE__->meta->column('updated_on')->add_trigger(
    on_save => sub {
        my $self = shift;
        $self->updated_on($self->created_on) unless $self->updated_on;
    }
);

sub parser {
    'WWW::Futaba::Parser';
}

# XXX 虹裏限定じゃないですか!!
sub catalog_thumbnail_uri {
    my $self = shift;
    my $uri = $self->thumbnail_uri;
    $uri =~ s/thumb/cat/;
    $uri;
}

sub save_response {
    my ($class, $res) = @_;

    Modoi->log(info => 'saving thread ' . $res->request->uri);

    my $parsed = $class->parser->parse($res) or return;

    my $thread = $class->new(uri => ($res->request ? $res->request->uri : $res->base));
    unless ($thread->load(speculative => 1)) {
        $thread->thumbnail_uri($parsed->thumbnail_uri);
        $thread->body($parsed->body);
        $thread->created_on($parsed->head->{datetime});
    }
    $thread->posts_count(scalar @{$parsed->posts});
    $thread->updated_on([$parsed->posts]->[-1] ? [$parsed->posts]->[-1]->head->{datetime} : $parsed->head->{datetime});
    $thread->save;
}

package Modoi::DB::Thread::Manager;
use base 'Rose::DB::Object::Manager';

sub object_class { 'Modoi::DB::Thread' }

__PACKAGE__->make_manager_methods('threads');

1;
