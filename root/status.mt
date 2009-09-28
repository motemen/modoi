? my ($context) = @_;
? $_mt->wrapper_file('_wrapper.mt', title => 'Status')->(sub {

? my $status;

<h2>Fetcher</h2>
<ul>
? $status = $context->server->proxy->fetcher->status;
? while (my ($uri, $status) = each %$status) {
    <li><a href="<?= $uri ?>"><?= $uri ?></a>: <?= $status->{percentage} ? sprintf '%.1f%%', $status->{percentage} : '-' ?> <a href="/fetcher/cancel?uri=<?= $uri ?>">cancel</a></li>
? }
</ul>

<h2>Watcher</h2>
<ul>
? $status = $context->server->proxy->watcher->status;
? foreach my $uri (keys %$status) {
    <li><a href="<?= $uri ?>"><?= $uri ?></a> <?= Modoi::DB::Thread->new(uri => $uri)->load->summary ?></li>
? }
</ul>

? });
