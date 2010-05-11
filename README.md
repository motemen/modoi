Modoi - Nijiura proxy
=====================

DESCRIPTION
-----------

虹裏プロキシです。

 * 開いたスレッドを監視し、自動で更新します。
 * 開いたスレッドを保存します。
 * スレッドや画像が消えてもキャッシュが残っていればそれを返します。
 * 開いた画像や外部にアップロードされたファイルをローカルに保存します。
 * 画像やファイルを事前読み込みします。

SYNOPSIS
--------
	$ perl sketch/modoi.psgi -c config.sample.yaml
	$ plackup sketch/modoi.psg -s AnyEvent::HTTPD -p 9999

プロキシとしてご利用下さい。

TODO
----
 * 古いモジュール消す
 * 検索
 * スマートフォン対応
 * プラグイン
 * 外部サイト連携…
