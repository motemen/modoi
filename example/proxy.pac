function FindProxyForURL(url, host) { 
    if (dnsDomainIs(host, '.2chan.net') ||
        dnsDomainIs(host, 'www.nijibox5.com')) {
        return 'PROXY localhost:3128';
    }
}
