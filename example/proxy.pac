function FindProxyForURL(url, host) {
    if (dnsDomainIs(host, '.2chan.net')) {
        return 'PROXY localhost:5678';
    }
}
