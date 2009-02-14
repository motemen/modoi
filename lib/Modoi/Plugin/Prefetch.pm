package Modoi::Plugin::Prefetch;
use strict;
use warnings;
use base qw(Modoi::Plugin);
use YAML;
use List::MoreUtils qw(uniq);
use URI;

__PACKAGE__->mk_accessors(qw(site_config));

sub init {
    my ($self, $context) = @_;

    $self->site_config({});

    $context->register_hook(
        $self,
        'server.response' => \&filter_response,
    );
}

sub filter_response {
    my ($self, $context, $args) = @_;
    my $res = $args->{response};

    $context->fetcher->fetch($_) foreach $self->find_links($res);
}

sub find_links {
    my ($self, $res) = @_;
    
    my $uri = $res->request->uri;
    my $site_config = $self->site_config_for($uri) or return;

    if (my $path = $site_config->{path}) {
        return unless $res->request->uri =~ /$path/;
    }

    my %links = ();

    my $rules = $site_config->{rules};
    my $content = $res->decoded_content or return;
    foreach my $rule (@$rules) {
        while ($content =~ /($rule->{regexp})/g) {
            my $frag = $1;
            my $uri;

            if ($rule->{rewrite}) {
                my @m = ($frag, $frag =~ /$rule->{regexp}/);
                $frag = $rule->{rewrite};
                $frag =~ s/\$(\d+)/$m[$1]/ge;
                $uri = $frag;
            } else {
                $uri = URI->new_abs($frag, $res->base);
            }

            if ($uri && !$links{$uri}++) {
                Modoi->context->log(info => "found link: $uri");
            }
        }
    }

    keys %links;
}

sub site_config_for {
    my ($self, $uri) = @_;

    $uri = URI->new($uri) unless ref $uri;

    if (!exists $self->site_config->{$uri->host}) {
        my $file;
        $self->load_assets_for($uri, '*.yaml', sub {
            $file = shift unless $file;
        });

        if ($file) {
            $self->site_config->{$uri->host} = YAML::LoadFile($file);
            Modoi->context->log(info => "found $file for $uri");
        } else {
            $self->site_config->{$uri->host} = undef;
        }
    }

    $self->site_config->{$uri->host};
}

1;
