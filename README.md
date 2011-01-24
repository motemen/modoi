Modoi
=====

modoi は虹裏プロキシです。あなたのマシンで起動させて、これを経由して虹裏にアクセスすることで便利に閲覧できます。

Feature
-------

以下の機能があります。このうち必要な機能だけを使うように設定できます。

- スレッド・画像をキャッシュ=スレが落ちても閲覧できる
- ブラウザに強くキャッシュさせて通信量を削減
- スレッド情報を DB に保存
- スレッドを定期監視
- 画像・ファイルの先読み
- HyperEstraier による検索

How To Use
----------

	git clone --recursive git://github.com/motemen/modoi.git
	cd modoi/
	cpanm --installdeps .
	cd modules/WWW-Futaba-Parser/
	cpanm --installdeps .
	cd ../..
	sqlite3 modoi.db < db/*.sql
	MODOI_AUTH=user:pass plackup modoi.psgi -p 5678

プロキシサーバが起動します。example/proxy.pac などを利用して、ブラウザがこのプロキシを通るようにすれば設定完了です。

TODO
----

 * 設定
 * WWW-Futaba-Parser のほうをなんとかする

Author
------

motemen <motemen@gmail.com>
