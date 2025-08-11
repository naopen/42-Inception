# 42-Inception ピアレビュー台本（日本人学生向け）
## レビュー時間目安：45分

---

## 🎬 **オープニング（5分）**

### **レビュアー（R）:**
「こんにちは！今日は42-Inceptionプロジェクトのレビューをさせていただきます。よろしくお願いします。」

「まず最初に、GitリポジトリのURLを共有していただけますか？」

### **レビュイー（S）:**
「はい、こちらです：[GitリポジトリURL]」

「プロジェクトのクローンをお願いします。評価は私のマシンで行います。」

### **R:**
```bash
git clone [リポジトリURL] inception_review
cd inception_review
pwd  # 現在のディレクトリを確認
```

「クローン完了しました。それではレビューを始めさせていただきます。」

---

## 📋 **Preliminaries - 事前確認（5分）**

### **R:**
「まず最初に、秘密情報の管理について確認させていただきます。」

```bash
# 認証情報の露出チェック
echo "=== 認証情報チェック ==="
grep -r "PASSWORD\|KEY\|SECRET" --exclude-dir=.git . | grep -v ".env"
```

「結果が何も表示されませんね。完璧です！」

「.envファイルの存在も確認します。」

```bash
ls -la srcs/.env
cat srcs/.env | head -5  # 構造だけ確認
```

### **S:**
「はい、すべての認証情報は.envファイルで管理しています。Gitにはコミットされていません。」

```bash
git status  # .envがuntracked filesにあることを示す
```

### **R:**
「素晴らしいです！セキュリティ面もしっかり考慮されていますね。」

---

## 🏗️ **General Instructions - 一般指示（10分）**

### **R:**
「次に、プロジェクトの構造を確認させていただきます。」

```bash
echo "=== ディレクトリ構造 ==="
tree -L 3 . | head -30
```

### **S:**
「要求された構造に完全に準拠しています。」
- 「Makefileがルートにあります」
- 「srcsフォルダ内にdocker-compose.ymlがあります」
- 「各サービスのDockerfileはrequirements内にあります」

### **R:**
「完璧な構造ですね。では、禁止事項のチェックを行います。」

```bash
echo "=== 禁止事項チェック ==="
echo -n "network: host: "; grep -r "network: host" srcs/ 2>/dev/null | wc -l
echo -n "links: "; grep -r "links:" srcs/ 2>/dev/null | wc -l
echo -n "--link: "; grep -r -- "--link" srcs/ 2>/dev/null | wc -l
echo -n "tail -f: "; grep -r "tail -f" srcs/requirements/ 2>/dev/null | wc -l
echo -n "sleep infinity: "; grep -r "sleep infinity" srcs/requirements/ 2>/dev/null | wc -l
```

「すべて0ですね。禁止事項は一切使用されていません。」

### **S:**
「はい、すべてDockerのベストプラクティスに従って実装しました。」

### **R:**
「では、クリーンアップして起動してみましょう。」

```bash
# 完全クリーンアップ
docker stop $(docker ps -qa) 2>/dev/null
docker rm $(docker ps -qa) 2>/dev/null
docker rmi -f $(docker images -qa) 2>/dev/null
docker volume rm $(docker volume ls -q) 2>/dev/null
docker network rm $(docker network ls -q) 2>/dev/null

echo "クリーンアップ完了"
```

---

## 🚀 **Mandatory Part - 起動と確認（15分）**

### **R:**
「それでは、Makefileを使ってプロジェクトをビルド・起動します。」

```bash
make
# または
make up
```

### **S:**
「ビルドには少し時間がかかります。その間、プロジェクトの概要を説明させていただきます。」

**説明ポイント：**
1. 「DockerとDocker Composeの違い」
   - 「Dockerは単一コンテナ、Docker Composeは複数コンテナのオーケストレーション」
2. 「DockerとVMの利点」
   - 「軽量、高速起動、リソース効率が良い」
3. 「ディレクトリ構造の妥当性」
   - 「各サービスが独立、設定とコードの分離」

### **R:**
「理解が深いですね。ビルドが完了したようなので、確認していきます。」

```bash
# コンテナ状態確認
docker compose -f srcs/docker-compose.yml ps

# 期待される出力：
# NAME        STATUS     PORTS
# nginx       Up         0.0.0.0:443->443/tcp
# wordpress   Up         9000/tcp
# mariadb     Up         3306/tcp
```

「3つのコンテナがすべて起動していますね。」

---

## 🔒 **SSL/TLS確認（5分）**

### **R:**
「SSL/TLSの設定を確認します。」

```bash
# HTTPS接続テスト
curl -kI https://localhost | head -5

# HTTP接続拒否確認
curl -I http://localhost 2>&1 | head -5
```

### **S:**
「HTTPSのみアクセス可能で、HTTPは拒否されます。TLS 1.2/1.3のみを使用しています。」

```bash
# TLSバージョン確認
echo | openssl s_client -connect localhost:443 2>/dev/null | grep "Protocol"
```

### **R:**
「TLSv1.3が使用されていますね。セキュリティ要件を満たしています。」

---

## 🌐 **WordPress動作確認（5分）**

### **R:**
「WordPressの動作を確認します。ブラウザでアクセスしてもよろしいですか？」

### **S:**
「はい、https://nkannan.42.fr でアクセスできます。」

「/etc/hostsの設定が必要な場合は、以下のコマンドを実行してください：」

```bash
echo "127.0.0.1 nkannan.42.fr" | sudo tee -a /etc/hosts
```

### **R:**
「WordPressが正常に表示されますね。管理者でログインしてみます。」

```bash
# 管理者情報確認
docker exec wordpress wp user list --allow-root --path=/var/www/wordpress
```

「管理者名に'admin'が含まれていないことを確認しました。」

「コメントを投稿してみます...投稿できました！」

---

## 💾 **永続性テスト（5分）**

### **R:**
「データの永続性をテストします。」

```bash
# テスト投稿作成
docker exec wordpress wp post create \
    --post_title="Persistence Test by Reviewer" \
    --post_content="このデータは再起動後も残るはずです" \
    --post_status=publish \
    --allow-root \
    --path=/var/www/wordpress

# 投稿ID: 5 (例)

# コンテナ再起動
docker compose -f srcs/docker-compose.yml restart

# 30秒待機
sleep 30

# データ確認
docker exec wordpress wp post get 5 --allow-root --path=/var/www/wordpress
```

### **S:**
「データが保持されています。ボリュームが正しく機能しています。」

### **R:**
「完璧です！すべての要件を満たしています。」

---

## 🎯 **評価まとめ（5分）**

### **R:**
「それでは評価をまとめさせていただきます。」

**チェックリスト確認：**
- ✅ 秘密情報の適切な管理
- ✅ 正しいディレクトリ構造
- ✅ 禁止事項なし
- ✅ 3つのDockerfile（自作）
- ✅ 適切なベースイメージ
- ✅ カスタムネットワーク
- ✅ ボリューム設定
- ✅ SSL/TLS（ポート443のみ）
- ✅ WordPress正常動作
- ✅ データ永続性

「すべての評価項目をクリアしています。素晴らしいプロジェクトです！」

### **S:**
「ありがとうございます！何か質問はありますか？」

### **R:**
「最後に、このプロジェクトで一番苦労した点を教えていただけますか？」

### **S:**
「WordPressとMariaDBの接続部分です。コンテナ間通信とタイミングの問題を解決するのに時間がかかりました。」

「wait_for_serviceという関数を実装して、MariaDBが完全に起動するまで待機するようにしました。」

### **R:**
「なるほど、実践的な解決策ですね。」

「改善提案があるとすれば、ログの集約やモニタリングの追加でしょうか。」

「でも、要件はすべて完璧に満たしています。」

**最終評価：100点 / Outstanding Project 🏆**

「お疲れ様でした！素晴らしいプロジェクトでした。」

### **S:**
「ありがとうございました！」

---

## 📝 **レビュー後の片付け**

```bash
# レビュアー側でのクリーンアップ
make fclean
cd ..
rm -rf inception_review

# hosts fileのクリーンアップ（必要に応じて）
sudo sed -i '' '/nkannan.42.fr/d' /etc/hosts  # Mac
# sudo sed -i '/nkannan.42.fr/d' /etc/hosts   # Linux
```

---

## 💡 **レビュアーのための追加確認事項**

もし時間があれば、以下も確認：

1. **ボーナス部分**（もしあれば）
   - Redis Cache
   - FTP Server
   - Static Website
   - Adminer

2. **詳細な技術質問**
   - 「php-fpmとは何か説明してください」
   - 「Docker networkのbridgeドライバーの仕組みは？」
   - 「SSL証明書の生成プロセスを説明してください」

3. **トラブルシューティング**
   - 「もしWordPressが接続できない場合、どうデバッグしますか？」
   - 「コンテナのログはどう確認しますか？」

---

## 🎬 **エンディング**

評価シートへの記入を完了し、フィードバックを提供して終了。

「今日はありがとうございました。とても勉強になりました！」

「Good luck with your next project! 🚀」
