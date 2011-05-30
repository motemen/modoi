package Modoi::Component::IndexEstraier;
use Mouse;
use Modoi;
use Search::Estraier;
use Try::Tiny;
use Data::Page;

extends 'Modoi::Component';

has node_url => (
    is  => 'rw',
    isa => 'Str',
    default => 'http://localhost:1978/node/modoi',
);

has node_user => (
    is  => 'rw',
    isa => 'Str',
    default => 'admin',
);

has node_password => (
    is  => 'rw',
    isa => 'Str',
    default => 'admin',
);

has node => (
    is  => 'rw',
    isa => 'Search::Estraier::Node',
    lazy_build => 1,
);

sub _build_node {
    my $self = shift;

    return Search::Estraier::Node->new(
        url => $self->node_url,
        user => $self->node_user,
        passwd => $self->node_password,
        croak_on_error => 1,
    );
}

sub INSTALL {
    my ($self, $context) = @_;
    $context->install_component('ParseHTML');
    $context->internal->router->connect(search => '/search', { handler => Modoi::Internal::Engine::IndexEstraier->new, method => 'search' });
    Modoi::Fetcher::Role::IndexEstraier->meta->apply($context->fetcher);
}

sub _utf8_off ($) {
    my $s = shift;
    utf8::encode $s if utf8::is_utf8 $s;
    return $s;
}

sub add {
    my ($self, $res, $req) = @_;

    my $url = $req->request_uri;
    my $parsed = Modoi->component('ParseHTML')->parse($res, $url) or return;
    if ($parsed->isa('WWW::Futaba::Parser::Result::Thread')) {
        my $doc = Search::Estraier::Document->new;
        $doc->add_attr('@uri', $req->request_uri);
        $doc->add_attr('@title', _utf8_off $parsed->body);
        $doc->add_attr('@thumbnail_url', $parsed->thumbnail_url) if $parsed->thumbnail_url;
        $doc->add_attr('@cdate', $parsed->datetime->iso8601) if $parsed->datetime;
        foreach ($parsed, $parsed->posts) {
            $doc->add_text(_utf8_off $_->body);
        }
        try {
            $self->node->put_doc($doc);
            Modoi->log(info => "successfully indexed $url");
        } catch {
            Modoi->log(warn => "error indexing $url: $_");
        }
    }
}

sub search {
    my ($self, $q, %args) = @_;

    $args{per_page} ||= 10
    $args{page}     ||= 1;

    Modoi->log(debug => "search: $q");

    my $cond = Search::Estraier::Condition->new;
       $cond->set_phrase($q);
       $cond->set_skip($args{per_page} * ( $args{page} - 1 ));

    my $res;
    try {
        $res = $self->node->search($cond, 0);
        if (not defined $res) {
            Modoi->log(warn => 'search failed:', $self->node->status);
        }
    } catch {
        Modoi->log(warn => "search failed: $_");
    };
    return undef unless $res;

    my $pager = Data::Page->new;
    $pager->entries_per_page($args{per_page});
    $pager->current_page($args{page});
    $pager->total_entries($res->hits);

    return {
        docs => [ map { $res->get_doc($_) } ( 0 .. $res->doc_num - 1 ) ],
        pager => $pager,
    };
}

sub status {
    my $self = shift;
    return {
        'Node URL'   => $self->node->{url},
        'Name'       => $self->node->name,
        '#Documents' => $self->node->doc_num,
        '#Words'     => $self->node->word_num,
    };
}

package Modoi::Fetcher::Role::IndexEstraier;
use Mouse::Role;

after modify_response => sub {
    my ($self, $res, $req) = @_;
    return unless $res->code eq '200';
    Modoi->component('IndexEstraier')->add($res, $req);
};

package Modoi::Internal::Engine::IndexEstraier;
use Mouse;
use Modoi;
use Text::Xslate qw(html_builder html_escape);

extends 'Modoi::Internal::Engine';

sub highlight_estraier_snippet {
    my $string = shift;
    my $html = '';
    foreach (split /\n/, $string) {
        if (/^(.+?)\t(.+)$/) {
            $html .= '<strong>' . html_escape($2) . '</strong>';
        } else {
            $html .= html_escape($_);
        }
    }
    return $html;
}

sub search {
    my ($self, $req) = @_;

    $self->tx->{function}->{highlight_estraier_snippet} ||= html_builder \&highlight_estraier_snippet;

    my $args = {};
    if (my $q = $req->param('q')) {
        $args->{q} = $q;
        if (my $res = Modoi->component('IndexEstraier')->search($q, page => scalar $req->param('page'))) {
            $args->{docs} = $res->{docs};
            $args->{pager} = $res->{pager};
        }
    }
    return $self->render_template('search.tx', $args);
}

1;
