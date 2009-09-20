use strict;
use warnings;
use Test::More tests => 10;
use Test::TCP;
use LWP::Simple 'get';
use HTTP::Request::Common;

test_tcp

server => sub {
    my $port = shift;
    HTTPMock->new($port)->run;
},

client => sub {
    local $Test::Builder::Level = $Test::Builder::Level + 3;
    use subs 'set_next';

    use_ok 'Modoi::Fetcher';

    my $port = shift;
    my $uri = "http://localhost:$port/";

    local *set_next = sub {
        my $uri = URI->new($uri . 'set_next');
           $uri->query_form(@_);
        get($uri);
    };

    {
        # いちおう set_next のテスト
        ok get($uri),   '何もなけりゃ 200 OK';
        set_next code => 404;
        ok !get($uri),  'set_next で 404 NOT FOUND 指定';
        ok get($uri),   'その次からまた 200';
    }

    my $fetcher = Modoi::Fetcher->new;
    isa_ok $fetcher->cache, 'Cache::MemoryCache';
    
    my $res;

    ok !$fetcher->fetch_cache($uri);
    set_next code => 404;
    $res = $fetcher->fetch(GET $uri);
    is $res->code, 404, 'キャッシュなしで 404 なら 404';

    $res = $fetcher->fetch(GET $uri);
    is $res->code, 200, '一度 200 をキャッシュすると…';
    ok $fetcher->fetch_cache($uri);

    set_next code => 404;
    $res = $fetcher->fetch(GET $uri);
    is $res->code, 200, '404 が返ってきてもキャッシュを返却';
};

package HTTPMock;
use base 'HTTP::Server::Simple::CGI';
use HTTP::Response;

my %Next;

sub handle_request {
    my ($self, $q) = @_;

    if ($q->path_info eq '/set_next') {
        %Next = %{$q->Vars};
        print "HTTP/1.0 200 OK\r\n\r\n";
        return;
    }

    my %params = (%{$q->Vars}, %Next);
    %Next = ();

    my $code    = $params{code} || 200;
    my $content = $params{content} || time; # なんか返す

    my $res = HTTP::Response->new($code);
    $res->content($content);
    $res->header(%params) if %params;

    print 'HTTP/1.0 ' . $res->as_string;
}

sub print_banner { }
