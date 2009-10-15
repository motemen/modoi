? my ($app) = @_;
? $_mt->wrapper_file('_wrapper.mt', title => 'Status')->(sub {

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

? my $status;

<h2>Watcher</h2>
<ul>
? $status = $app->watcher_status;
? foreach my $uri (keys %$status) {
?   my $thread = $status->{$uri};
    <li>
    <a href="<?= $uri ?>"><span class="catalog-thumbnail-container"><img src="<?= $thread->catalog_thumbnail_uri ?>" /></span></a> <a href="<?= $uri ?>"><?= $thread->summary ?></a>
    (<?= $thread->response_count ?>)
    <span class="timestamp"><?= $thread->created_on ?></span>/<span class="timestamp"><?= $thread->updated_on ?></span>
    </li>
? }
</ul>

<h2>Fetcher</h2>
<ul>
? $status = $app->fetcher_status;
? while (my ($uri, $status) = each %$status) {
    <li><a href="<?= $uri ?>"><?= $uri ?></a>: <?= $status->{percentage} ? sprintf '%.1f%%', $status->{percentage} : '-' ?> <a href="/fetcher/cancel?uri=<?= $uri ?>">cancel</a></li>
? }
</ul>

? });
