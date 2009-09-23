? my ($context) = @_;
? $_mt->wrapper_file('_wrapper.mt', title => 'Status')->(sub {

<h2>Fetcher</h2>
<ul>
? my $status = $context->server->proxy->fetcher->status;
? while (my ($uri, $status) = each %$status) {
    <li><a href="<?= $uri ?>"><?= $uri ?></a>: <?= $status->{percentage} ? sprintf '%.1f%%', $status->{percentage} : '-' ?> <a href="/fetcher/cancel?uri=<?= $uri ?>">cancel</a></li>
? }
</ul>

? });
