package Modoi::Extractor;
use Any::Moose;

with 'Modoi::Role::HasAsset';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

use List::MoreUtils qw(uniq);
use HTML::TreeBuilder::XPath;

sub asset_name { 'extractor' }

sub extract {
    my ($self, $res) = @_;

    my $content = $res->content;
    my $config = $self->load_asset_yaml($res);
    my @result;

    my $tree;

    foreach my $rule (@{$config->{rules}}) {
        if (my $xpath = $rule->{xpath}) {
            $tree ||= do {
                my $tree = HTML::TreeBuilder::XPath->new;
                $tree->parse($content);
                $tree;
            };
            push @result, map { $_->string_value } $tree->findnodes($xpath);
        } elsif (my $regexp = $rule->{regexp}) {
            while ($content =~ /($regexp)/g) {
                my $fragment = $1;
                my $uri = URI->new_abs($fragment, $res->base);
                if ($rule->{rewrite}) {
                    my @matches = ($fragment, $fragment =~ /$regexp/);
                    $uri = $rule->{rewrite};
                    $uri =~ s/\$(\d+)/$matches[$1]/ge;
                }
                push @result, $uri;
            }
        }
    }
    
    if ($tree) {
        $tree->delete;
    }

    uniq @result;
}

1;

__END__

=head1 NAME

Modoi::Extractor - スレッドからメディアを探しだす
