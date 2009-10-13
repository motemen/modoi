? my ($context, $app) = @_;
? $_mt->wrapper_file('_wrapper.mt', title => 'Threads')->(sub {

<style type="text/css">
.catalog-thumbnail-container {
    width: 50px;
    display: inline-block;
    margin-right: 3px;
    text-align: center;
    vertical-align: middle;
}

span.timestamp {
    font-size: smaller;
}

li {
    margin: 15px auto;
}

h2 {
    clear: both;
}
</style>
<ul>
? foreach my $thread (@{$app->threads}) {
    <li>
    <a href="<?= $thread->uri ?>"><span class="catalog-thumbnail-container"><img src="<?= $thread->catalog_thumbnail_uri ?>" /></span></a> <a href="<?= $thread->uri ?>"><?= $thread->summary ?></a>
    (<?= $thread->response_count ?>)
    <span class="timestamp"><?= $thread->created_on ?></span>/<span class="timestamp"><?= $thread->updated_on ?></span>
    </li>
? }
</ul>

? });
