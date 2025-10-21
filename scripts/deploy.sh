#!/bin/bash
set -e

# GCPデプロイスクリプト

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# プロジェクトIDを取得
PROJECT_ID=$(gcloud config get-value project)
REGION="asia-northeast1"
REPOSITORY="todo-app"

if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}エラー: GCPプロジェクトが設定されていません${NC}"
  echo "gcloud config set project YOUR_PROJECT_ID を実行してください"
  exit 1
fi

echo -e "${GREEN}=== Todo App デプロイメント ===${NC}"
echo "プロジェクトID: $PROJECT_ID"
echo "リージョン: $REGION"
echo ""

# 1. Artifact Registryの認証
echo -e "${YELLOW}[1/5] Artifact Registryに認証中...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# 2. バックエンドイメージのビルドとプッシュ（AMD64アーキテクチャ）
echo -e "${YELLOW}[2/5] バックエンドイメージをビルド中（AMD64）...${NC}"
docker buildx build --platform linux/amd64 \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/backend:latest \
  -f backend/Dockerfile.prod ./backend --push

# 3. フロントエンドイメージのビルドとプッシュ（AMD64アーキテクチャ）
echo -e "${YELLOW}[3/5] フロントエンドイメージをビルド中（AMD64）...${NC}"
docker buildx build --platform linux/amd64 \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/frontend:latest \
  -f frontend/Dockerfile.prod ./frontend --push

# 4. Terraformの初期化と適用
echo -e "${YELLOW}[4/5] Terraformでインフラを構築中...${NC}"
cd terraform

if [ ! -f "terraform.tfvars" ]; then
  echo -e "${RED}エラー: terraform.tfvars が見つかりません${NC}"
  echo "terraform.tfvars.example をコピーして設定してください"
  exit 1
fi

terraform init
terraform plan
read -p "Terraformを適用しますか? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
  terraform apply
else
  echo "デプロイをキャンセルしました"
  exit 0
fi

cd ..

# 5. デプロイ完了
echo -e "${GREEN}=== デプロイ完了 ===${NC}"
echo ""
echo "フロントエンドURL:"
terraform -chdir=terraform output -raw frontend_url
echo ""
echo "バックエンドURL:"
terraform -chdir=terraform output -raw backend_url
echo ""
