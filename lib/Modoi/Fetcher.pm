package Modoi::Fetcher;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use URI::Fetch;
use Modoi::Util;

__PACKAGE__->mk_accessors(qw(config cache));

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

sub init {
    my $self = shift;
    my $cache_config = $self->config->{cache};
    $cache_config->{module}->require or die $@;
    $self->cache($cache_config->{module}->new($cache_config->{options}));
}

sub fetch {
    my ($self, $uri) = splice @_, 0, 2;

    URI::Fetch->fetch(
        "$uri",
        ForceResponse => 1,
        Cache => $self->cache,
        CacheEntryGrep => sub {
            my $res = shift;
            foreach (Modoi->context->plugins('Filter::Fetcher')) {
                $_->filter($res)
                    or Modoi->context->log(info => "do not cache: $uri") and return;
            }
            1;
        },
        @_,
    );
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
