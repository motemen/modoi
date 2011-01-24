package Modoi::Component::StoreDB;
use Mouse;
use Modoi;

extends 'Modoi::Component';

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
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

1;
