? my ($thread) = @_;
? $_mt->wrapper_file('iphone/_wrapper.mt')->(sub {

<div class="thread">
? foreach my $elem (@{$thread->{head_elements}}) {
?=  encoded_string(ref $elem ? $elem->as_HTML('') : $elem);
? }
? foreach my $res (@{$thread->{responses}}) {
?=  encoded_string(ref $res ? $res->as_HTML('') : $res);
? }
</div>

? });
