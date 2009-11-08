package Modoi::DB::Thread;
use strict;
use warnings;
use base 'Modoi::DB::Object';
use Modoi::Parser;

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
    our $Parser ||= Modoi::Parser->new;
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

    # TODO パーズする前に判断
    my $thread_info = $class->parser->parse($res) or return;

    my $thread = $class->new(uri => ($res->request ? $res->request->uri : $res->base));
    $thread->load(speculative => 1);
    while (my ($key, $value) = each %$thread_info) {
        $thread->$key($value) if $class->meta->column($key);
    };
    $thread->response_count(scalar @{$thread_info->{responses}});
    $thread->save;
}

package Modoi::DB::Thread::Manager;
use base 'Rose::DB::Object::Manager';

sub object_class { 'Modoi::DB::Thread' }

__PACKAGE__->make_manager_methods('threads');

1;
