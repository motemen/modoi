? my ($index) = @_;
? $_mt->wrapper_file('iphone/_wrapper.mt')->(sub {

? foreach my $thread (@{$index->{threads}}) {
<div class="thread">
?   foreach my $elem (@$thread) {
?=    encoded_string(ref $elem ? $elem->as_HTML('') : $elem);
?   }
</div>
? }

? });
