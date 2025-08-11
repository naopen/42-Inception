#!/bin/bash

# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    test_inception.sh                                  :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nkannan <nkannan@student.42tokyo.jp>       +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/11 10:00:00 by nkannan         #+#    #+#              #
#    Updated: 2025/08/11 10:00:00 by nkannan          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# 42-Inception 完全評価テストスクリプト
# このスクリプトはすべての評価項目を自動的にチェックします

# カラーコード
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# スコア
SCORE=0
MAX_SCORE=100
FAILED_TESTS=""

# テスト結果
pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    SCORE=$((SCORE + $2))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    FAILED_TESTS="$FAILED_TESTS\n  - $1"
}

info() {
    echo -e "${CYAN}ℹ️  INFO${NC}: $1"
}

section() {
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# プロジェクトルートの検出
if [ -f "Makefile" ] && [ -d "srcs" ]; then
    PROJECT_ROOT=$(pwd)
elif [ -f "../Makefile" ] && [ -d "../srcs" ]; then
    PROJECT_ROOT=$(cd .. && pwd)
else
    echo -e "${RED}Error: Cannot find project root${NC}"
    exit 1
fi

cd "$PROJECT_ROOT"

# ヘッダー
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         42-INCEPTION EVALUATION TEST SUITE               ║"
echo "║                   Version 1.0                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ====================
# PRELIMINARIES (10点)
# ====================
section "PRELIMINARIES (10点)"

# 認証情報チェック
info "認証情報の保護をチェック中..."
if ! grep -r "PASSWORD\|KEY\|SECRET" --exclude-dir=.git --exclude="*.md" --exclude="test_inception.sh" . 2>/dev/null | grep -v ".env" | grep -v "secrets/" > /dev/null; then
    pass "認証情報がコードに含まれていない" 5
else
    fail "認証情報がコードに露出している"
fi

# .envファイルの存在
if [ -f "srcs/.env" ]; then
    pass ".envファイルが存在する" 5
else
    fail ".envファイルが存在しない"
fi

# ====================
# GENERAL INSTRUCTIONS (20点)
# ====================
section "GENERAL INSTRUCTIONS (20点)"

# ディレクトリ構造
info "ディレクトリ構造をチェック中..."
STRUCTURE_OK=true
[ -f "Makefile" ] || STRUCTURE_OK=false
[ -d "srcs" ] || STRUCTURE_OK=false
[ -f "srcs/docker-compose.yml" ] || STRUCTURE_OK=false
[ -d "srcs/requirements" ] || STRUCTURE_OK=false
[ -d "srcs/requirements/nginx" ] || STRUCTURE_OK=false
[ -d "srcs/requirements/wordpress" ] || STRUCTURE_OK=false
[ -d "srcs/requirements/mariadb" ] || STRUCTURE_OK=false

if $STRUCTURE_OK; then
    pass "必須ディレクトリ構造が正しい" 5
else
    fail "ディレクトリ構造が不正"
fi

# Dockerfileの存在
DOCKERFILE_COUNT=$(find srcs/requirements -name "Dockerfile" | wc -l)
if [ "$DOCKERFILE_COUNT" -ge 3 ]; then
    pass "各サービスにDockerfileが存在 ($DOCKERFILE_COUNT個)" 5
else
    fail "Dockerfileが不足 ($DOCKERFILE_COUNT個)"
fi

# 禁止事項チェック
info "禁止事項をチェック中..."
FORBIDDEN_OK=true

grep -r "network: host" srcs/ 2>/dev/null && FORBIDDEN_OK=false
grep -r "links:" srcs/ 2>/dev/null && FORBIDDEN_OK=false
grep -r -- "--link" srcs/ 2>/dev/null && FORBIDDEN_OK=false
grep -r "tail -f" srcs/requirements/ 2>/dev/null && FORBIDDEN_OK=false
grep -r "sleep infinity" srcs/requirements/ 2>/dev/null && FORBIDDEN_OK=false
grep -r "while true" srcs/requirements/ 2>/dev/null && FORBIDDEN_OK=false

if $FORBIDDEN_OK; then
    pass "禁止事項が含まれていない" 10
else
    fail "禁止事項が検出された"
fi

# ====================
# DOCKER BASICS (15点)
# ====================
section "DOCKER BASICS (15点)"

# ベースイメージチェック
info "ベースイメージをチェック中..."
BASE_IMAGES=$(grep "^FROM" srcs/requirements/*/Dockerfile | grep -E "debian:bullseye|alpine:" | wc -l)
if [ "$BASE_IMAGES" -ge 3 ]; then
    pass "適切なベースイメージを使用" 5
else
    fail "不適切なベースイメージ"
fi

# DockerHub使用チェック
if ! grep -E "FROM.*/" srcs/requirements/*/Dockerfile | grep -v "debian:\|alpine:" > /dev/null; then
    pass "DockerHubの既製イメージを使用していない" 5
else
    fail "DockerHubの既製イメージを使用している"
fi

# latestタグチェック
if ! grep "latest" srcs/requirements/*/Dockerfile > /dev/null; then
    pass "latestタグを使用していない" 5
else
    fail "latestタグが検出された"
fi

# ====================
# RUNNING SERVICES (20点)
# ====================
section "RUNNING SERVICES (20点)"

# サービスのビルドと起動
info "サービスをビルド・起動中..."
if make up > /dev/null 2>&1; then
    pass "Makefileでサービスが起動する" 5
    
    # 起動待機
    sleep 30
    
    # コンテナ状態チェック
    NGINX_RUNNING=$(docker ps | grep nginx | wc -l)
    WP_RUNNING=$(docker ps | grep wordpress | wc -l)
    DB_RUNNING=$(docker ps | grep mariadb | wc -l)
    
    if [ "$NGINX_RUNNING" -eq 1 ]; then
        pass "NGINXコンテナが実行中" 5
    else
        fail "NGINXコンテナが実行されていない"
    fi
    
    if [ "$WP_RUNNING" -eq 1 ]; then
        pass "WordPressコンテナが実行中" 5
    else
        fail "WordPressコンテナが実行されていない"
    fi
    
    if [ "$DB_RUNNING" -eq 1 ]; then
        pass "MariaDBコンテナが実行中" 5
    else
        fail "MariaDBコンテナが実行されていない"
    fi
else
    fail "サービスの起動に失敗"
    SCORE=$((SCORE - 15))  # この場合、後続テストができないので減点
fi

# ====================
# NETWORK & VOLUMES (15点)
# ====================
section "NETWORK & VOLUMES (15点)"

# ネットワーク確認
if docker network ls | grep inception > /dev/null; then
    pass "カスタムネットワークが存在する" 5
else
    fail "カスタムネットワークが存在しない"
fi

# ボリューム確認
if docker volume ls | grep wordpress > /dev/null; then
    pass "WordPressボリュームが存在する" 5
else
    fail "WordPressボリュームが存在しない"
fi

if docker volume ls | grep mariadb > /dev/null; then
    pass "MariaDBボリュームが存在する" 5
else
    fail "MariaDBボリュームが存在しない"
fi

# ====================
# SSL/TLS SECURITY (10点)
# ====================
section "SSL/TLS SECURITY (10点)"

# HTTPS接続テスト
info "HTTPS接続をテスト中..."
if curl -kI https://localhost 2>/dev/null | grep "HTTP" > /dev/null; then
    pass "HTTPSポート(443)でアクセス可能" 5
else
    fail "HTTPSポート(443)でアクセス不可"
fi

# HTTP接続拒否テスト
if ! curl -I http://localhost 2>&1 | grep "Failed to connect" > /dev/null; then
    fail "HTTPポート(80)が開いている（セキュリティ違反）"
else
    pass "HTTPポート(80)が適切にブロックされている" 5
fi

# ====================
# WORDPRESS CONFIGURATION (10点)
# ====================
section "WORDPRESS CONFIGURATION (10点)"

# WordPress動作確認
info "WordPress設定をチェック中..."
if docker exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress 2>/dev/null; then
    pass "WordPressが正しくインストールされている" 5
    
    # 管理者名チェック
    ADMIN_USER=$(docker exec wordpress wp user list --allow-root --path=/var/www/wordpress 2>/dev/null | grep administrator | awk '{print $2}')
    if echo "$ADMIN_USER" | grep -E "admin|Admin|administrator|Administrator" > /dev/null; then
        fail "管理者名に'admin'が含まれている"
    else
        pass "管理者名が要件を満たしている" 5
    fi
else
    fail "WordPressがインストールされていない"
fi

# ====================
# 結果サマリー
# ====================
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    テスト結果サマリー                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"

# スコア表示
if [ $SCORE -ge 90 ]; then
    COLOR=$GREEN
    GRADE="Outstanding Project 🏆"
elif [ $SCORE -ge 75 ]; then
    COLOR=$YELLOW
    GRADE="Good Project ⭐"
elif [ $SCORE -ge 50 ]; then
    COLOR=$YELLOW
    GRADE="Acceptable Project"
else
    COLOR=$RED
    GRADE="Needs Improvement"
fi

echo -e "\n${COLOR}スコア: $SCORE / $MAX_SCORE${NC}"
echo -e "${COLOR}評価: $GRADE${NC}"

# 失敗したテスト
if [ -n "$FAILED_TESTS" ]; then
    echo -e "\n${RED}失敗したテスト:${NC}"
    echo -e "$FAILED_TESTS"
fi

# 推奨事項
echo -e "\n${CYAN}推奨テストコマンド:${NC}"
echo "  docker compose -f srcs/docker-compose.yml logs --tail=50"
echo "  docker exec wordpress wp user list --allow-root --path=/var/www/wordpress"
echo "  docker exec mariadb mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'"
echo "  curl -kI https://localhost"

# クリーンアップオプション
echo -e "\n${YELLOW}テスト後のクリーンアップ:${NC}"
echo "  make down    # コンテナを停止"
echo "  make fclean  # 完全クリーンアップ"

exit $((100 - SCORE))
