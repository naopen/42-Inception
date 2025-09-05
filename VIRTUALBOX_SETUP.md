# Virtual Box環境でのセットアップ手順

## 概要
Virtual Box環境では、ホストとの共有フォルダ（vboxsf）の制約により、MariaDBのUNIXソケットファイルの作成に問題が発生する場合があります。この問題を解決するため、Docker管理の名前付きボリュームを使用する構成に変更しています。

## 問題の詳細
- Virtual Boxの共有フォルダ（vboxsf）ではUNIXソケットファイルの作成に制限がある
- `/var/run/mysqld/mysqld.sock`の作成が失敗する
- MariaDBが「Can't connect to local MySQL server through socket」エラーで起動しない

## 解決方法
1. **名前付きボリューム**: Dockerが管理するボリュームを使用
2. **ソケットファイルの移動**: `/tmp/mysql.sock`を使用
3. **tmpfsマウント**: コンテナ内の一時ファイルシステムを使用

## セットアップ手順

### 1. 環境設定ファイルの準備
```bash
# Virtual Box環境用の設定をコピー
cd ~/host-pc/Documents/GitHub/42-Inception/srcs
cp .env.virtualbox .env
```

### 2. ホストファイルの設定（必要に応じて）
```bash
# ドメイン名を/etc/hostsに追加
sudo echo "127.0.0.1 nkannan.42.fr" >> /etc/hosts
```

### 3. プロジェクトのビルドと起動
```bash
cd ~/host-pc/Documents/GitHub/42-Inception

# 既存のコンテナがある場合はクリーンアップ
make fclean

# ビルドと起動
make up

# ログの確認
make logs

# 特定のサービスのログを確認
make logs-mariadb
```

### 4. 動作確認
```bash
# コンテナの状態確認
make ps

# MariaDBの接続テスト
make db

# WordPress設定情報の表示
make info
```

## トラブルシューティング

### MariaDBコンテナ内での診断
```bash
# コンテナに入る
docker exec -it mariadb /bin/bash

# ヘルスチェック実行（作成した診断スクリプト）
/usr/local/bin/../requirements/mariadb/tools/healthcheck.sh

# プロセス確認
ps aux | grep mysql

# ソケットファイル確認
ls -la /tmp/mysql.sock

# 設定ファイル確認
cat /etc/mysql/mariadb.conf.d/50-server.cnf
```

### よくあるエラーと対処法

#### エラー: "Can't connect to local MySQL server through socket"
**原因**: ソケットファイルの作成に失敗
**対処**: 
1. コンテナを再起動: `make restart`
2. ログを確認: `make logs-mariadb`
3. 完全にクリーンアップして再構築: `make fclean && make up`

#### エラー: Permission denied
**原因**: ファイル権限の問題
**対処**:
```bash
# Docker権限確認
sudo usermod -aG docker $USER
# 再ログインが必要

# ボリューム削除して再作成
docker volume rm srcs_mariadb_data srcs_wordpress_data
make up
```

## ボリューム管理

### 名前付きボリュームの確認
```bash
# ボリューム一覧
docker volume ls

# ボリューム詳細情報
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

### データのバックアップ
```bash
# MariaDBデータのバックアップ
docker run --rm -v srcs_mariadb_data:/data -v $(pwd):/backup alpine tar czf /backup/mariadb_backup.tar.gz -C /data .

# WordPressデータのバックアップ
docker run --rm -v srcs_wordpress_data:/data -v $(pwd):/backup alpine tar czf /backup/wordpress_backup.tar.gz -C /data .
```

### データの復元
```bash
# MariaDBデータの復元
docker run --rm -v srcs_mariadb_data:/data -v $(pwd):/backup alpine tar xzf /backup/mariadb_backup.tar.gz -C /data

# WordPressデータの復元
docker run --rm -v srcs_wordpress_data:/data -v $(pwd):/backup alpine tar xzf /backup/wordpress_backup.tar.gz -C /data
```

## 注意事項

1. **データの永続化**: 名前付きボリュームを使用しているため、`make fclean`でデータが削除されます
2. **環境の切り替え**: Mac環境では元の設定（bind mount）を使用してください
3. **セキュリティ**: .envファイルには機密情報が含まれるため、Gitにコミットしないでください

## その他のコマンド

```bash
# 環境情報の表示
make info

# 評価要件のチェック
make check

# WordPressにシェルアクセス
make shell-wordpress

# MariaDBにシェルアクセス
make shell-mariadb

# WordPress CLI使用例
make wp user list
```
