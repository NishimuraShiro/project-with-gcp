#!/bin/bash
set -e

# terraform.tfvars を自動生成するスクリプト

PROJECT_ID=$(gcloud config get-value project)
REGION="asia-northeast1"
ZONE="asia-northeast1-a"

if [ -z "$PROJECT_ID" ]; then
  echo "エラー: GCPプロジェクトが設定されていません"
  echo "gcloud config set project YOUR_PROJECT_ID を実行してください"
  exit 1
fi

echo "=== terraform.tfvars を作成します ==="
echo "プロジェクトID: $PROJECT_ID"
echo ""

# パスワードを入力
read -sp "データベースパスワードを入力してください: " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
  echo "エラー: パスワードを入力してください"
  exit 1
fi

# terraform.tfvars を作成
cat > terraform/terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
region     = "$REGION"
zone       = "$ZONE"

db_user     = "todoapp_user"
db_password = "$DB_PASSWORD"
db_name     = "todo_db"

backend_image  = "${REGION}-docker.pkg.dev/${PROJECT_ID}/todo-app/backend:latest"
frontend_image = "${REGION}-docker.pkg.dev/${PROJECT_ID}/todo-app/frontend:latest"
EOF

echo ""
echo "terraform/terraform.tfvars を作成しました！"
echo ""
echo "内容を確認:"
cat terraform/terraform.tfvars | grep -v "db_password"
echo "db_password = ********"
echo ""
echo "次のコマンドでデプロイを実行できます:"
echo "  ./scripts/deploy.sh"
