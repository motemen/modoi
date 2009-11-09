? my ($index) = @_;
? $_mt->wrapper_file('iphone/_wrapper.mt')->(sub {

? foreach my $thread (@{$index->{threads}}) {
?   foreach my $elem (@$thread) {
?=    encoded_string(ref $elem ? $elem->as_HTML : $elem);
?   }
? }

? });
