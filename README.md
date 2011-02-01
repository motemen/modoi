Modoi
=====

modoi は虹裏プロキシです。あなたのマシンで起動させて、これを経由して虹裏にアクセスすることで便利に閲覧できます。

Feature
-------

以下の機能があります。このうち必要な機能だけを使うように設定できます。

 * スレッド・画像をキャッシュ=スレが落ちても閲覧できる (Component::Cache)
 * ブラウザのキャッシュを利用して通信量を削減 (Component::UseBrowserCache)
 * スレッド情報を DB に保存 (Component::StoreDB)
 * スレッドを定期監視 (Component::Watch)
 * 画像・ファイルの先読み (Component::Prefetch)
 * HyperEstraier による検索 (Component::IndexEstraier)
 * プロキシの設定をしない利用 (Component::WebProxy)
   * http://localhost:5678/http/www.2chan.net/b/ などにアクセスできるようになります。
   * さらに Component::WebProxy::TouchView を使用すると、スマートフォン用のビューも用意されます。

How To Use
----------

	git clone --recursive git://github.com/motemen/modoi.git
	cd modoi/
	cpanm Module::Install Module::Install::AuthorTests
	cpanm --installdeps . ./modules/WWW-Futaba-Parser
	sqlite3 modoi.db < db/*.sql
    cp config.sample.yaml config.yaml
	plackup modoi.psgi -p 5678

プロキシサーバが起動します。example/proxy.pac などを利用して、ブラウザがこのプロキシを通るようにすれば設定完了です。

config.yaml 内の Modoi > auth もしくは環境変数 `MODOI_AUTH` を `user:password` の形式にしておくと、Basic 認証をかけることができます。

TODO
----

 * 設定
   * HTTP::Config つかってるところの設定
 * スマフォビュー

Author
------

motemen <motemen@gmail.com>
