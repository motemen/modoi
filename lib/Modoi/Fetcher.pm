package Modoi::Fetcher;
use strict;
use warnings;
use base qw(Modoi::Component);
use URI;
use URI::Fetch;
use LWP::UserAgent;
use DateTime;
use List::MoreUtils qw(any);
use Modoi::Util;
use Modoi::DB::Thread;

__PACKAGE__->mk_accessors(qw(config cache thread_rule));

our $UserAgent = LWP::UserAgent->new(timeout => 10);

sub new {
    my ($class, %args) = @_;
    my $config = delete $args{config};
    my $self = $class->SUPER::new(%args);
       $self->init_config($config);
       $self->init;
    $self;
}

sub init_config {
    my ($self, $config) = @_;

    $config->{cache}->{module} ||= 'Cache::FileCache';
    $config->{cache}->{options}->{cache_root} ||= '.fetcher/cache';

    if ($config->{cache}->{module} eq 'Cache::FileCache') {
        if (my $cache_root = $config->{cache}->{options}->{cache_root}) {
            $config->{cache}->{options}->{cache_root} = Modoi::Util::absolutize($cache_root);
        }
    }

    $self->config($config);
}

sub thread_rule_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless ref $uri;
    
    unless (exists $self->thread_rule->{$uri->host}) {
        my $file;
        $self->load_assets_for($uri, 'thread.yaml', sub {
            $file = shift unless $file;
        });

        if ($file) {
            $self->thread_rule->{$uri->host} = YAML::LoadFile($file);
            Modoi->context->log(info => "found $file for $uri");
        } else {
            $self->thread_rule->{$uri->host} = undef;
        }
    }

    $self->thread_rule->{$uri->host};
}

sub init {
    my $self = shift;
    my $cache_config = $self->config->{cache};
    $cache_config->{module}->require or die $@;
    $self->cache($cache_config->{module}->new($cache_config->{options}));
    $self->thread_rule({});
}

sub fetch {
    my ($self, $uri) = splice @_, 0, 2;

    $uri = URI->new($uri) unless ref $uri;

    Modoi->context->log(debug => "fetch $uri");

    my $res = URI::Fetch->fetch(
        "$uri",
        ForceResponse => 1,
        UserAgent => $UserAgent,
        Cache => $self->cache,
        CacheEntryGrep => sub {
            my $res = shift;
            my @should_cache = Modoi->context->run_hook('fetcher.should_cache', { response => $res });
            if (any { not $_ } @should_cache) {
                Modoi->context->log(debug => "fetcher.should_cache $uri returned false: not going to cache.");
                return;
            }
            1;
        },
        @_
    );

    my $thread_info;
    if ($res->is_success) {
        if (my $rule = $self->thread_rule_for($uri)) {
            # TODO Modoi::Rule
            if ($uri->path =~ /$rule->{path}/) {
                Modoi->context->log(debug => "save thread info $uri");
                $thread_info = Modoi->context->parser->parse_response($res->http_response);
                my $thread = Modoi::DB::Thread->new(
                    uri           => $uri,
                    thumbnail_uri => $thread_info->{thumbnail},
                    datetime      => $thread_info->{datetime},
                    summary       => $thread_info->{summary},
                );
                eval { $thread->load } or $thread->save;
            }
        }
    } else {
        Modoi->context->log(debug => "fetching $uri failed: " $res->message);
    }

    Modoi->context->run_hook('fetcher.filter_response', { response => $res, thread => $thread_info });

    $res;
}

sub request {
    my ($self, $req) = splice @_, 0, 2;

    $self->fetch(
        $req->request_uri,
        ETag => scalar $req->header('If-None-Match'),
        LastModified => scalar $req->header('If-Modified-Since'),
        @_
    );
}

1;
