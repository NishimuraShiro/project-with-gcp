#!/bin/bash
set -e

# GCP認証セットアップスクリプト

echo "=== GCP認証のセットアップ ==="
echo ""

# プロジェクトIDを取得
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
  echo "エラー: GCPプロジェクトが設定されていません"
  echo "gcloud config set project YOUR_PROJECT_ID を実行してください"
  exit 1
fi

echo "プロジェクトID: $PROJECT_ID"
echo ""

# 認証方法を選択
echo "認証方法を選択してください:"
echo "1) Application Default Credentials (推奨・簡単)"
echo "2) サービスアカウントキー（本番環境向け）"
read -p "選択 (1 or 2): " choice

if [ "$choice" = "1" ]; then
  echo ""
  echo "Application Default Credentialsを設定します..."
  echo "ブラウザが開きますので、Googleアカウントでログインしてください"
  gcloud auth application-default login
  echo ""
  echo "認証完了！"

elif [ "$choice" = "2" ]; then
  echo ""
  echo "サービスアカウントを作成します..."

  SA_NAME="terraform-deploy"
  SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

  # サービスアカウントを作成
  gcloud iam service-accounts create $SA_NAME \
    --display-name="Terraform Deployment Service Account" || echo "サービスアカウントは既に存在します"

  # 必要な権限を付与
  echo "権限を付与中..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/editor"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.admin"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"

  # キーファイルを作成
  KEY_FILE="$HOME/.gcp/${PROJECT_ID}-terraform-key.json"
  mkdir -p "$HOME/.gcp"

  echo "キーファイルを作成中: $KEY_FILE"
  gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SA_EMAIL

  # 環境変数を設定
  echo ""
  echo "以下を ~/.bashrc または ~/.zshrc に追加してください:"
  echo ""
  echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$KEY_FILE\""
  echo ""

  # 現在のシェルで設定
  export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"

  echo "認証完了！"
  echo "注意: このキーファイルは安全に保管し、Gitにコミットしないでください"

else
  echo "無効な選択です"
  exit 1
fi

echo ""
echo "認証設定が完了しました！"
echo "次のコマンドでデプロイを実行できます:"
echo "  ./scripts/deploy.sh"
