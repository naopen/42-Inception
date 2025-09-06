# Cross-Platform Support Notes

## 概要
このプロジェクトはmacOSとLinux (VirtualBox VM)の両環境で動作するように設計されています。

## 自動環境検出

Makefileが自動的にOSを検出し、適切なパスを設定します：

| OS | データパス | 自動検出 |
|---|---|---|
| **Linux (VM)** | `/home/username/data` | ✅ |
| **macOS** | `/Users/username/data` | ✅ |

## 環境別の実行方法

### macOSでの実行
```bash
# macOSでは自動的に /Users/username/data を使用
make up
```

### Linux VM (評価環境)での実行
```bash
# Linux VMでは自動的に /home/username/data を使用
make up
```

## 評価要件への準拠

42の評価要件では `/home/login/data` にボリュームを配置する必要があります。
- **Linux VM環境**: ✅ 要件を満たす
- **macOS環境**: 開発用（評価時はVM使用）

## VirtualBox特有の問題対応

### vboxsfファイルシステムの制限
- **問題**: UNIXソケットファイルが作成できない
- **解決**: MariaDBのソケットファイルを`/tmp`に配置

### 確認済みの設定
```ini
# mariadb/conf/50-server.cnf
socket = /tmp/mysql.sock
pid-file = /tmp/mysqld.pid
```

## 環境確認コマンド

```bash
# 現在の設定を確認
make info

# 環境チェック
make check
```

## トラブルシューティング

### macOSで "Operation not supported" エラー
- `/home`ディレクトリが存在しないため発生
- 自動的に`/Users/username/data`を使用するので問題なし

### VMでMySQLソケットエラー
- tmpfsまたは`/tmp`を使用して解決済み
- TCP接続（port 3306）も利用可能

## 開発者向けメモ

環境変数`DATA_PATH`はMakefileで自動設定されます：
```makefile
# OS Detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    DATA_PATH = /home/$(USER)/data
else ifeq ($(UNAME_S),Darwin)
    DATA_PATH = $(HOME)/data
endif
```

Docker Composeは`${DATA_PATH}`を使用してボリュームをマウント：
```yaml
volumes:
  wordpress_data:
    device: ${DATA_PATH}/wordpress
  mariadb_data:
    device: ${DATA_PATH}/mariadb
```
