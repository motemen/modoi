package Modoi::Proxy;
use Any::Moose;

use Modoi;
use Modoi::Fetcher;
use Modoi::Watcher;
use Modoi::Extractor;
use Modoi::DB::Thread;

use Coro;

use URI;
use HTTP::Request::Common qw(GET);
use HTML::TreeBuilder::XPath;
use Scalar::Util qw(weaken);

with 'Modoi::Role::Configurable';

has 'fetcher', (
    is  => 'rw',
    isa => 'Modoi::Fetcher',
    lazy_build => 1,
);

has 'extractor', (
    is  => 'rw',
    isa => 'Modoi::Extractor',
    default => sub { Modoi::Extractor->new },
);

has 'watcher', (
    is  => 'rw',
    isa => 'Modoi::Watcher',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub DEFAULT_CONFIG {
    +{ proxy => { host => '*.2chan.net' } };
}

sub _build_fetcher {
    my $self = shift;
    weaken (my $proxy = $self);
    Modoi::Fetcher->new(on_fresh_response => sub { $proxy->save_thread($_[0]) });
}

sub _build_watcher {
    my $self = shift;
    weaken (my $proxy = $self);
    Modoi::Watcher->new(fetcher => $self->fetcher, on_response => sub { $proxy->do_prefetch($_[0]) });
}

sub process {
    my ($self, $req) = @_;

    my $res = do {
        local $LWP::UserAgent::AnyEvent::Coro::UserAgent = $req->headers->header('User-Agent');
        if (uc $req->method eq 'GET') {
            my $res = $self->fetcher->fetch($req);
            [ $res->redirects ]->[0] || $res;
        } else {
            $self->fetcher->simple_request($req);
        }
    };

    if ($res->code =~ /^59\d$/) {
        die $res->headers->header('Reason');
    }

    if (($res->headers->header('X-Modoi-Source') || '') ne 'cache') {
        $self->watcher->start_watching_if_necessary($res);
    }

    $self->do_prefetch($res);

    $res;
}

# fetcher->on_fresh_response callback
sub save_thread {
    my ($self, $res) = @_;
    Modoi::DB::Thread->save_response($res);
}

# watcher->on_response callback
sub do_prefetch {
    my ($self, $res) = @_;

    return unless $res->is_success;
    return unless $res->content_type =~ m'^text/';

    foreach my $uri ($self->extractor->extract($res)) {
        Modoi->log(info => "prefetch $uri");
        async { $self->fetcher->fetch(GET $uri) };
    }
}

sub rewrite_links {
    my ($self, $res, $rewriter) = @_;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($res->decoded_content);

    my @nodes = $tree->findnodes('//*[@href or @src]');
    foreach my $node (@nodes) {
        foreach my $attr (qw(href src)) {
            if (my $uri = $node->attr($attr)) {
                $uri = URI->new_abs($uri, $res->base);
                if ($self->config->condition('proxy')->pass(GET $uri)) {
                    local $_ = $uri;
                    $node->attr($attr => $rewriter->($uri));
                }
            }
        }
    }

    $res->content($tree->root->as_HTML);
}

1;
