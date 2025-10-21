#!/bin/bash
set -e

# GCP初期セットアップスクリプト

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== GCP初期セットアップ ===${NC}"
echo ""

# プロジェクトIDを取得
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}エラー: GCPプロジェクトが設定されていません${NC}"
  echo "gcloud config set project YOUR_PROJECT_ID を実行してください"
  exit 1
fi

echo "プロジェクトID: $PROJECT_ID"
echo ""

# 必要なAPIを有効化
echo -e "${YELLOW}必要なAPIを有効化中...${NC}"
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  vpcaccess.googleapis.com \
  servicenetworking.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  compute.googleapis.com

echo -e "${GREEN}APIの有効化完了${NC}"
echo ""

# Artifact Registryリポジトリを作成
echo -e "${YELLOW}Artifact Registryリポジトリを作成中...${NC}"
REGION="asia-northeast1"
REPOSITORY="todo-app"

gcloud artifacts repositories create $REPOSITORY \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for Todo App" || echo "リポジトリは既に存在します"

echo -e "${GREEN}Artifact Registryリポジトリ作成完了${NC}"
echo ""

# terraform.tfvarsの作成を促す
echo -e "${YELLOW}次のステップ:${NC}"
echo "1. terraform/terraform.tfvars.example を terraform/terraform.tfvars にコピー"
echo "2. terraform/terraform.tfvars を編集してプロジェクト情報を設定"
echo "3. scripts/deploy.sh を実行してデプロイ"
echo ""
echo -e "${GREEN}セットアップ完了！${NC}"
