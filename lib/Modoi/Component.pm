package Modoi::Component;
use Mouse;
use HTML::Entities;

sub INSTALL {
    my $self = shift;
    # override this
}

sub RESTORE_STATE {
    my $self = shift;
    # override this
}

sub STORE_STATE {
    my $self = shift;
    # override this
}

sub status {
    my $self = shift;
    # override this
}

sub BUILD {
    my $self = shift;
    $self->RESTORE_STATE;
}

sub status_as_html {
    my $self = shift;
    return $self->_htmlify($self->status);
}

sub install {
    my ($class, $context) = @_;
    my $self = $class->new;
    $self->INSTALL($context);
    return $self;
}

sub _htmlify {
    my ($self, $object) = @_;

    return '' unless $object;

    if (blessed $object && $object->can('as_html')) {
        return $object->as_html;
    } elsif (blessed $object && $object->isa('URI')) {
        my $url_html = $self->_htmlify("$object");
        return qq(<a href="$url_html">$url_html</a>);
    } elsif (!ref $object) {
        return encode_entities("$object", '<>&"');
    } elsif (UNIVERSAL::isa($object, 'ARRAY')) {
        my $html = "<ul>\n";
        foreach my $item (@$object) {
            $html .= sprintf "  <li>%s</li>\n", $self->_htmlify($item);
        }
        $html .= "</ul>\n";
        return $html;
    } elsif (UNIVERSAL::isa($object, 'HASH')) {
        my $html = "<table><tbody>\n";
        while (my ($key, $value) = each %$object) {
            $html .= sprintf "  <tr><th>%s</th><td>%s</td></tr>\n", $key, $self->_htmlify($value);
        }
        $html .= "</tbody></table>\n";
        return $html;
    } else {
        return encode_entities("$object", '<>&"');
    }
}

1;
