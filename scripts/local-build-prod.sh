#!/bin/bash
set -e

# 本番環境用Dockerイメージをローカルでビルド・テスト

echo "=== 本番環境用イメージのビルド ==="
echo ""

# バックエンドのビルド
echo "[1/4] バックエンドをビルド中..."
docker build -t todo-backend-prod:latest -f backend/Dockerfile.prod ./backend

# フロントエンドのビルド
echo "[2/4] フロントエンドをビルド中..."
docker build -t todo-frontend-prod:latest -f frontend/Dockerfile.prod ./frontend

echo ""
echo "=== ビルド完了 ==="
echo ""
echo "ローカルでテストする場合:"
echo ""
echo "# バックエンドを起動:"
echo "docker run -p 8080:8080 -e DB_HOST=host.docker.internal -e DB_USER=root -e DB_PASSWORD=rootpassword -e DB_NAME=todo_db todo-backend-prod:latest"
echo ""
echo "# フロントエンドを起動:"
echo "docker run -p 3000:3000 -e NEXT_PUBLIC_API_URL=http://localhost:8080 todo-frontend-prod:latest"
echo ""
