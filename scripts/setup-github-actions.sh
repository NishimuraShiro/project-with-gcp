#!/bin/bash
set -e

# GitHub Actions用のGCPサービスアカウントをセットアップ

PROJECT_ID=$(gcloud config get-value project)
SA_NAME="github-actions-deploy"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "=== GitHub Actions CI/CD セットアップ ==="
echo "プロジェクトID: $PROJECT_ID"
echo ""

# 1. サービスアカウントを作成
echo "[1/5] サービスアカウントを作成中..."
gcloud iam service-accounts create $SA_NAME \
  --display-name="GitHub Actions Deployment" \
  --description="Service account for automated deployment from GitHub Actions" \
  2>/dev/null || echo "サービスアカウントは既に存在します"

# 2. 必要な権限を付与
echo "[2/5] 権限を付与中..."

# Cloud Run管理者
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin" \
  --condition=None

# Artifact Registry書き込み
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer" \
  --condition=None

# Cloud Build編集者
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.editor" \
  --condition=None

# サービスアカウントユーザー
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser" \
  --condition=None

# ストレージ管理者（ビルドアーティファクト用）
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin" \
  --condition=None

# 3. キーファイルを作成
echo "[3/5] キーファイルを作成中..."
KEY_FILE="github-actions-key.json"

gcloud iam service-accounts keys create $KEY_FILE \
  --iam-account=$SA_EMAIL

echo ""
echo "キーファイルが作成されました: $KEY_FILE"
echo ""

# 4. キーをBase64エンコード
echo "[4/5] キーをBase64エンコード中..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  BASE64_KEY=$(base64 -i $KEY_FILE)
else
  # Linux
  BASE64_KEY=$(base64 -w 0 $KEY_FILE)
fi

echo ""
echo "=== GitHub Secretsの設定 ==="
echo ""
echo "GitHubリポジトリの Settings > Secrets and variables > Actions で以下のシークレットを追加してください："
echo ""
echo "1. GCP_PROJECT_ID"
echo "   値: $PROJECT_ID"
echo ""
echo "2. GCP_SA_KEY"
echo "   値: (以下の内容をコピー)"
echo ""
echo "$BASE64_KEY"
echo ""
echo "3. BACKEND_IMAGE_NAME"
echo "   値: asia-northeast1-docker.pkg.dev/$PROJECT_ID/todo-app/backend"
echo ""
echo "4. FRONTEND_IMAGE_NAME"
echo "   値: asia-northeast1-docker.pkg.dev/$PROJECT_ID/todo-app/frontend"
echo ""
echo "5. REGION"
echo "   値: asia-northeast1"
echo ""
echo ""
echo "[5/5] 完了！"
echo ""
echo "注意: $KEY_FILE は機密情報です。"
echo "GitHubに設定後、このファイルを削除してください："
echo "  rm $KEY_FILE"
