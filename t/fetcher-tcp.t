use strict;
use warnings;
use Test::More tests => 17;
use Test::TCP;
use LWP::Simple 'get';
use HTTP::Request::Common;
use Coro;

use Modoi::Config {
    logger  => { dispatchers => [] },
    fetcher => {
        serve_cache => { content_type => 'image/*' },
    },
};

test_tcp

server => sub {
    my $port = shift;
    HTTPMock->new($port)->run;
},

client => sub {
    local $Test::Builder::Level = $Test::Builder::Level + 3;

    use_ok 'Modoi::Fetcher';

    my $port = shift;
    my $uri = "http://localhost:$port/";

    use subs 'set_next';
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

    isa_ok $fetcher->cache,  'Cache::MemoryCache';
    isa_ok $fetcher->config, 'Modoi::Config::Object';
    isa_ok $fetcher->config->condition('serve_cache'), 'Modoi::Condition';
    
    my $res;

    ok !$fetcher->fetch_cache($uri), '(まだキャッシュない)';
    set_next code => 404;
    $res = $fetcher->fetch(GET $uri);
    is $res->code, 404, 'キャッシュなしで 404 なら 404';

    $res = $fetcher->fetch(GET $uri);
    is $res->code, 200, '一度 200 をキャッシュすると…';
    ok $fetcher->fetch_cache($uri), '(キャッシュされた)';

    set_next code => 404;
    $res = $fetcher->fetch(GET $uri);
    is $res->code, 200, '404 が返ってきてもキャッシュを返却';

    {
        set_next sleep => 1, content => 'sleeping';
        my $first_request_done;
        my $f1 = async {
            my $res = $fetcher->fetch(GET $uri . 'sleep');
            $first_request_done++;
            is $res->content, "sleeping\n", '最初の fetch()';
        };
        my $f2 = async {
            my $res = $fetcher->fetch(GET $uri . 'sleep');
            ok $first_request_done,         '最初の fetch() が完了するまで待つ';
            is $res->content, "sleeping\n", 'かつ、キャッシュを取得';
        };
        $f1->join;
        $f2->join;
    }

    {
        set_next sleep => 1, code => 500, content => 'ise';
        my $f1 = async {
            my $res = $fetcher->fetch(GET $uri . 'sleep_ise');
            is $res->content, undef,         '最初の fetch() は失敗するけど…';
        };
        my $f2 = async {
            my $res = $fetcher->fetch(GET $uri . 'sleep_ise');
            like $res->content, qr/^\d+\n$/, '次の fetch() はキャッシュがないのを知ってちゃんとリクエスト';
        };
        $f1->join;
        $f2->join;
    }
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

    my %params = (%{$q->Vars}, %Next); %Next = ();

    my $code    = delete $params{code} || 200;
    my $content = delete $params{content} || time; # なんか返す
    
    if (my $sleep = delete $params{sleep}) {
        sleep $sleep;
    }

    my $res = HTTP::Response->new($code);
    $res->content($content);
    $res->header(%params) if %params;

    print 'HTTP/1.0 ' . $res->as_string;
}

sub print_banner { }
