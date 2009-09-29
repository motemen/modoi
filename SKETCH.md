サーバの機能
============

/status
-------
 * watcher が監視してるスレ (Watcher つくろうね)
 * リクエスト状況

とかを一覧したい、ログみたり

/search
-------
 * Estraier

スレ一覧、管理
--------------
やっぱ欲しいよなあ、いらないスレの削除・タグとかの管理

Role
====

Modoi::Role::Configurable
-------------------------

 * interface config = Modoi->config->(lc $class) ?
 * interface cond($name) = Modoi::Condition->new($self->config->{$name}) ?

config.yaml
===========

	server:
	  port: 3128
	proxy:
	  serve_cache:
	    content_type: image/*
	  rule:
	    - host: 2chan.net$
	    - host: ^www.nijibox\d+.com$
	fetcher:
	  serve_cache:
	    - content_type: image/*
	  watch:
	    host: *.2chan.net
	    content_type: text/html
	fetcher:
	  cache:
	    module: Cache::File
	    args:
	      cache_root: .cache
	watcher:
	  interval: 180
	logger:
	  min_level: debug

インターフェース
================

LWP::UA:Coro
------------

 * UA にプログレス ひゅー
 * セマフォを UA に

Fetcher
-------

 * interface fetch($req) => $res
   深遠な基準を基にキャッシュしたりしなかったりしてレスポンスを返す
 * interface fetch_uri($uri) == fetch(GET $uri);

Extractor
---------
 * interface extract($res) => \@uri

Proxy
-----
 * interface process($req) => $res
 * interface do_prefetch($res)
 * interface watch($uri) => 
 * has Modoi::Fetcher
 * has Modoi::Extractor

Server
------
 * interface handle_request($he_req) => $he_res
 * has Modoi::Proxy
 * has HTTP::Engine

vim: set filetype=markdown tabstop=4:
