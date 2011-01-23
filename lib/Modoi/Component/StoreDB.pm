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

around request => sub {
    my ($orig, $self, @args) = @_;

    my $req = $args[0];
    my $url = $req->request_uri;
    my $res = $self->$orig(@args);

    Modoi->log(debug => "parsing $url");
    if (my $parsed = Modoi->component('ParseHTML')->parse($res, $url)) {
        Modoi->log(debug => "parsed: $url ->", $parsed);
        if ($parsed->isa('WWW::Futaba::Parser::Result::Thread')) {
            my %args = (
                image_url     => $parsed->image_url,
                thumbnail_url => $parsed->thumbnail_url,
                body          => $parsed->body,
                posts_count   => scalar @{[ $parsed->posts ]},
                created_on    => $parsed->datetime,
                updated_on    => $parsed->posts->[-1] && $parsed->posts->[-1]->datetime,
            );
            if (my $row = Modoi->db->single(thread => { url => $url })) {
                $row->update({ %args });
            } else {
                Modoi->db->insert(
                    thread => { url => $url, %args }
                );
            }
        }
    }

    return $res;
};

package Modoi::DB::Schema;
use Teng::Schema::Declare;

table {
    name 'thread';
    pk 'url';
    columns qw(url image_url thumbnail_url body posts_count created_on updated_on);
};

1;
