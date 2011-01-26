package Modoi::Component::StoreDB;
use Mouse;
use Modoi;

extends 'Modoi::Component';

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
    $context->internal->router->connect(threads => '/threads', { handler => Modoi::Internal::Engine::StoreDB->new, method => 'threads' });
    Modoi::Fetcher::Role::StoreDB->meta->apply($context->fetcher);
}

sub status {
    my $self = shift;
    return {
        'dsn' => Modoi->db->connect_info->[0],
        'Stored threads'
            => Modoi->db->search_by_sql('SELECT COUNT(*) AS count FROM thread')->next->get_column('count')
    };
}

package Modoi::Fetcher::Role::StoreDB;
use Mouse::Role;
use Modoi;

after modify_response => sub {
    my ($self, $res, $req) = @_;

    return unless $res->code eq '200';

    my $url = $req->request_uri;
    my $parsed = Modoi->component('ParseHTML')->parse($res, $url) or return;

    if ($parsed->isa('WWW::Futaba::Parser::Result::Thread')) {
        my %args = (
            image_url     => $parsed->image_url,
            thumbnail_url => $parsed->thumbnail_url,
            body          => $parsed->body,
            posts_count   => scalar @{[ $parsed->posts ]},
            created_on    => $parsed->datetime,
            updated_on    => $parsed->posts->[-1] && $parsed->posts->[-1]->datetime,
        );
        Modoi->log(debug => 'store db:', \%args);
        if (my $row = Modoi->db->single(thread => { url => $url })) {
            $row->update({ %args });
        } else {
            Modoi->db->insert(
                thread => { url => $url, %args }
            );
        }
    }
};

package Modoi::DB::Schema;
use Teng::Schema::Declare;

table {
    name 'thread';
    pk 'url';
    columns qw(url image_url thumbnail_url body posts_count created_on updated_on);
};

package Modoi::Internal::Engine::StoreDB;
use Mouse;
use Modoi;

extends 'Modoi::Internal::Engine';

our $DATA = do { local $/; <DATA> };

sub threads {
    my ($self, $req) = @_;
    my $page = $req->param('page') || 1;
    my ($threads, $pager) = Modoi->db->search_with_pager('thread', {}, { order_by => 'created_on DESC', page => $page, rows => 10 });
    return $self->render($DATA, { threads => $threads, pager => $pager });
}

1;

__DATA__

<p class="pager">
: if $pager.previous_page {
  <a href="?page=<: $pager.previous_page :>">&laquo; prev</a>
: }
page <: $pager.current_page :>
: if $pager.has_next {
  <a href="?page=<: $pager.next_page :>">next &raquo;</a>
: }
</p>
<ul class="threads">
: for $threads -> $thread {
  <li>
  : if $thread.thumbnail_url {
    <img src="<: $thread.thumbnail_url :>" class="thumbnail">
  : }
  <a href="<: $thread.url :>" class="title"><: $thread.body :></a>
  <time><: $thread.created_on :></time>
  </li>
: }
</ul>
