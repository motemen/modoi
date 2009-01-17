package Madoi::Plugin::HandleContent::Fetch;
use strict;
use warnings;
use base qw(Madoi::Plugin::HandleContent);
use YAML;
use List::MoreUtils qw(uniq);

__PACKAGE__->mk_accessors(qw(find_rule));

sub init {
    my $self = shift;
    $self->find_rule({});
}

sub filter {
    my ($self, $content_ref, $res) = @_;
    return unless $$content_ref;
    
    my $uri = $res->request->uri;
    unless ($self->find_rule->{$uri->host}) {
        my $file;
        $self->load_assets_for($uri, '*.yaml', sub {
            $file = shift unless $file;
        });

        if ($file) {
            $self->find_rule->{$uri->host} = YAML::LoadFile($file);
            Madoi->context->log(info => "found $file for $uri");
        } else {
            return;
        }
    }

    my @links = ();

    my $rules = $self->find_rule->{$uri->host};
    foreach my $rule (@$rules) {
        while ($$content_ref =~ /($rule->{regexp})/g) {
            my $frag = $1;

            if ($rule->{rewrite}) {
                my @m = ($frag, $frag =~ /$rule->{regexp}/);
                $frag = $rule->{rewrite};
                $frag =~ s/\$(\d+)/$m[$1]/ge;
                push @links, $frag;
            } else {
                push @links, URI->new_abs($frag, $res->base);
            }

            Madoi->context->log(debug => "found link: $links[-1]");
        }
    }

    Madoi->context->downloader->download($_) foreach uniq @links;
}

sub will_modify { 0 }

1;
