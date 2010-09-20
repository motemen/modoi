? my ($index) = @_;
? $_mt->wrapper_file('iphone/_wrapper.mt')->(sub {
? foreach my $thread ($index->threads) {
<div class="thread">
  <div class="thumbnail">
?   my $link = $thread->image_link_elem;
?   my $html = $link && $link->as_HTML('') || '';
?   $html =~ s/align=\S+//; # XXX
?=  encoded_string $html;
  </div>
? foreach my $post ($thread->posts) {
    <div>
?=    encoded_string $post->as_HTML('')
    </div>
? }
</div>
? }

? });
