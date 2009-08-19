package Modoi::Plugin::Estraier;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use Search::Estraier;
use Regexp::Assemble;

sub init {
    my ($self, $context) = @_;

    my $regexp = $self->config->{regexp};
    my $ra = Regexp::Assemble->new;
    foreach (ref $regexp eq 'ARRAY' ? @$regexp : ($regexp)) {
        $ra->add($_);
    }
    $self->{uri_regexp} = $ra->re;

    $self->config->{url}      ||= 'http://localhost:1978/node/modoi';
    $self->config->{username} ||= 'admin';
    $self->config->{password} ||= 'admin';
    $self->config->{timeout}  ||= 30;

    $self->{node} = Search::Estraier::Node->new(
        url => $self->config->{url},
    );
    $self->{node}->set_auth($self->config->{username}, $self->config->{password});
    $self->{node}->set_timeout($self->config->{timeout});

    $context->register_hook(
        $self,
        'fetcher.filter_response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;

    return if $args->{response}->is_error;
    return unless $args->{response};
    return unless $args->{response}->uri =~ $self->{uri_regexp};

    $context->log(info => 'Going to index entry ' . $args->{response}->uri);

    my $doc = Search::Estraier::Document->new;
    $doc->add_attr('@uri'       => $args->{thread}->{uri});
    $doc->add_attr('@title'     => $args->{thread}->{summary});
    $doc->add_attr('@cdate'     => $args->{thread}->{datetime});
    $doc->add_attr('@thumbnail' => $args->{thread}->{thumbnail});
    $doc->add_text($args->{thread}->{body});

    $self->{node}->put_doc($doc) or $context->log(error => "Put failure: " . $self->{node}->status);
}

# XXX
{
    no warnings 'redefine';
    require HTTP::Message;
    require Encode;
    *HTTP::Message::_utf8_downgrade = sub { utf8::downgrade($_[0], 1) or Encode::_utf8_off($_[0]) };
}

package Modoi::Server::Engine::Search;
use base qw(Modoi::Server::Engine);

sub handle {
    my ($self, $req) = @_;

    my $node = Modoi->context->plugin('Estraier')->{node};

    my $result = { title => 'Search', link => '/search' };

    my $query = $req->param('q') or return $result;
    $result->{title} .= qq' "$query"';

    my $cond = Search::Estraier::Condition->new;
       $cond->set_phrase($req->param('q'));

    if (my $nres = $node->search($cond, 0)) {
        $result->{docs} = [
            map {
                my $doc = $nres->get_doc($_);
                   $doc->{snippet_html} = htmlify_snippet($doc->snippet);
                $doc;
            } (0 .. $nres->doc_num - 1)
        ];
    } else {
        warn $node->status;
        die $node->status;
    }

    $result;
}

sub escape_html {
    my $string = shift;
       $string =~ s/&/&amp;/g;
       $string =~ s/"/&quot;/g;
       $string =~ s/</&lt;/g;
       $string =~ s/>/&gt;/g;
    $string;
}

sub htmlify_snippet {
    my $snippet = shift;

    join '', map {
        if (/.+\t(.+)/) {
            sprintf '<strong>%s</strong>', escape_html($1);
        } else {
            escape_html($_);
        }
    } split /\n/, $snippet;
}

sub template {
    \<<'__TEMPLATE__';
[% WRAPPER _wrapper.tt %]
<div style="margin-top: 1em; padding: 1em; border: 1px solid #736859">
<form method="GET" action="/search">
<input type="text" name="q" value="[% engine.request.param('q') | html %]" />
<input type="submit" value="Search" />
</form>
</div>
<div id="search-result">
[% FOREACH d IN docs %]
<div class="search-result-entry">
[% IF d.attr('@thumbnail') %]<p class="thumbnail"><img src="[% d.attr('@thumbnail') | html %]"></p>[% END %]
<p class="title"><a href="[% d.attr('@uri') | html %]">[% d.attr('@title') | html %]</a></p>
<p class="snippet">[% d.snippet_html %]</p>
</div>
[% END %]
</div>
[% END %]
__TEMPLATE__
}

1;
