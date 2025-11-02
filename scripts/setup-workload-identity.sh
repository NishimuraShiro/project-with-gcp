#!/bin/bash
set -e

# Workload Identity Federation for GitHub Actions

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
SERVICE_ACCOUNT="github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com"
WORKLOAD_IDENTITY_POOL="github-pool"
WORKLOAD_IDENTITY_PROVIDER="github-provider"
REPO_OWNER="NishimuraShiro"  # GitHubユーザー名
REPO_NAME="project-with-gcp"  # リポジトリ名

echo "=== Workload Identity Federation セットアップ ==="
echo "プロジェクトID: $PROJECT_ID"
echo "プロジェクト番号: $PROJECT_NUMBER"
echo "GitHubリポジトリ: $REPO_OWNER/$REPO_NAME"
echo ""

# 1. IAM Service Account Credentials APIを有効化
echo "[1/6] 必要なAPIを有効化中..."
gcloud services enable iamcredentials.googleapis.com \
  --project=$PROJECT_ID

# 2. Workload Identity Poolを作成
echo "[2/6] Workload Identity Poolを作成中..."
gcloud iam workload-identity-pools create $WORKLOAD_IDENTITY_POOL \
  --location="global" \
  --description="Pool for GitHub Actions" \
  --display-name="GitHub Pool" \
  --project=$PROJECT_ID \
  2>/dev/null || echo "プールは既に存在します"

# 3. Workload Identity Providerを作成（GitHub用）
echo "[3/6] Workload Identity Providerを作成中..."
gcloud iam workload-identity-pools providers create-oidc $WORKLOAD_IDENTITY_PROVIDER \
  --location="global" \
  --workload-identity-pool=$WORKLOAD_IDENTITY_POOL \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '$REPO_OWNER'" \
  --project=$PROJECT_ID \
  2>/dev/null || echo "プロバイダーは既に存在します"

# 4. サービスアカウントに権限をバインド
echo "[4/6] サービスアカウントに権限をバインド中..."
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL}/attribute.repository/${REPO_OWNER}/${REPO_NAME}" \
  --project=$PROJECT_ID

# 5. Workload Identity Provider の完全なリソース名を取得
echo "[5/6] Workload Identity Provider情報を取得中..."
WORKLOAD_IDENTITY_PROVIDER_FULL=$(gcloud iam workload-identity-pools providers describe $WORKLOAD_IDENTITY_PROVIDER \
  --location="global" \
  --workload-identity-pool=$WORKLOAD_IDENTITY_POOL \
  --project=$PROJECT_ID \
  --format="value(name)")

echo ""
echo "=== GitHub Secretsの設定 ==="
echo ""
echo "GitHubリポジトリの Settings > Secrets and variables > Actions で以下のシークレットを追加してください："
echo ""
echo "1. GCP_PROJECT_ID"
echo "   値: $PROJECT_ID"
echo ""
echo "2. GCP_WORKLOAD_IDENTITY_PROVIDER"
echo "   値: $WORKLOAD_IDENTITY_PROVIDER_FULL"
echo ""
echo "3. GCP_SERVICE_ACCOUNT"
echo "   値: $SERVICE_ACCOUNT"
echo ""
echo "4. BACKEND_IMAGE_NAME"
echo "   値: asia-northeast1-docker.pkg.dev/$PROJECT_ID/todo-app/backend"
echo ""
echo "5. FRONTEND_IMAGE_NAME"
echo "   値: asia-northeast1-docker.pkg.dev/$PROJECT_ID/todo-app/frontend"
echo ""
echo "6. REGION"
echo "   値: asia-northeast1"
echo ""
echo ""
echo "[6/6] 完了！"
echo ""
echo "次のステップ:"
echo "1. 上記のGitHub Secretsを設定"
echo "2. .github/workflows/deploy.yml を更新（Workload Identity使用版）"
echo "3. mainブランチにプッシュしてテスト"
