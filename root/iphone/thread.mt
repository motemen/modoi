? my ($thread) = @_;
? $_mt->wrapper_file('iphone/_wrapper.mt')->(sub {

  <div class="thumbnail"><img src="<?= $thread->{thumbnail_uri} ?>" /></div>
? foreach my $res (@{$thread->{responses}}) {
  <div class="res"><?= $res ?></div>
? }

? });
