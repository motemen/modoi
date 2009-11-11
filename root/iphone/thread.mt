? my ($thread) = @_;
? $_mt->wrapper_file('iphone/_wrapper.mt')->(sub {

<div class="thread">
  <div class="thumbnail"><img src="<?= $thread->{thumbnail_uri} ?>" /></div>
? foreach my $res (@{$thread->{responses}}) {
?=  encoded_string(ref $res ? $res->as_HTML('') : $res)
? }
</div>

? });
