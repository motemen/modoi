package Modoi::Fetcher;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use URI;
use URI::Fetch;
use DateTime;
use List::MoreUtils qw(any);
use Path::Class qw(dir);
use Scalar::Util qw(blessed);
use Modoi::Util;
use Modoi::DB::Thread;

__PACKAGE__->mk_accessors(qw(config cache thread_rule));

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
        Cache => $self->cache,
        CacheEntryGrep => sub {
            my $res = shift;
            my @should_cache = Modoi->context->run_hook('fetcher.should_cache', { response => $res });
            return if any { not $_ } @should_cache;
            1;
        },
        @_
    );

    if ($res->is_success) {
        if (my $rule = $self->thread_rule_for($uri)) {
            # TODO Modoi::Rule
            if ($uri->path =~ /$rule->{path}/) {
                Modoi->context->log(debug => "save thread info $uri");
                my $info = Modoi->context->parser->parse_response($res);
                my $thread = Modoi::DB::Thread->new(
                    uri           => $uri,
                    thumbnail_uri => $info->{thumbnail},
                    datetime      => $info->{datetime},
                    summary       => $info->{summary},
                );
                eval { $thread->load };
                $thread->save;
            }
        }
    }

    Modoi->context->run_hook('fetcher.filter_response', { response => $res });

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

# XXX XXX XXX
sub class_id {
    my $self = shift;
    my $pkg = ref $self || $self;
       $pkg =~ s/Modoi:://;

    join '-', split /::/, $pkg;
}

sub assets_dir {
    my $self = shift;
    my $context = Modoi->context;

    if ($self->config->{assets_path}) {
        return $self->config->{assets_path};
    }

    my $assets_base = dir($context->config->{assets_path} || ($FindBin::Bin, 'assets'));
    $assets_base->subdir('core', $self->class_id);
}

sub assets_dir_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless blessed $uri;

    $self->assets_dir->subdir($uri->host);
}

sub load_assets_for {
    my ($self, $uri, $rule, $callback) = @_;

    $uri = URI->new($uri) unless blessed $uri;

    unless (blessed($rule) && $rule->isa('File::Find::Rule')) {
        $rule = File::Find::Rule->name($rule)->extras({ follow => 1 });
    }

    my @segments = $uri->path_segments;
    while (@segments) {
        pop @segments;
        foreach my $file ($rule->in($self->assets_dir_for($uri)->subdir(@segments))) {
            my $base = File::Basename::basename($file);
            $callback->($file, $base);
        }
    }
}

1;
