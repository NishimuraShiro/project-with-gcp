# GCP デプロイメントガイド

このドキュメントでは、Todo アプリケーションを Google Cloud Platform (GCP) にデプロイする手順を説明します。

## アーキテクチャ

- **Cloud Run**: バックエンド（Express + TypeScript）とフロントエンド（Next.js）
- **Cloud SQL**: MySQL 8.0 データベース
- **VPC Connector**: Cloud Run と Cloud SQL 間のプライベート接続
- **Artifact Registry**: Docker イメージの保管
- **Secret Manager**: データベースパスワードの安全な保管
- **Terraform**: Infrastructure as Code (IaC)

## 前提条件

1. GCP アカウントと有効な請求先アカウント
2. インストール済みのツール:
   - [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install)
   - [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.0)
   - Docker

## デプロイ手順

### 1. 初期セットアップ

```bash
# GCPプロジェクトを作成（または既存のプロジェクトを使用）
gcloud projects create YOUR_PROJECT_ID --name="Todo App"

# プロジェクトを設定
gcloud config set project YOUR_PROJECT_ID

# 請求先アカウントを有効化（GCPコンソールで実施）

# 必要なAPIを有効化
./scripts/setup-gcp.sh
```

### 2. Terraform 設定

```bash
# terraform.tfvars を作成
cd terraform
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars を編集
vi terraform.tfvars
```

`terraform.tfvars` の設定例:
```hcl
project_id = "your-gcp-project-id"
region     = "asia-northeast1"
zone       = "asia-northeast1-a"

db_user     = "todoapp_user"
db_password = "YOUR-SECURE-PASSWORD-HERE"  # 安全なパスワードに変更
db_name     = "todo_db"

backend_image  = "asia-northeast1-docker.pkg.dev/your-gcp-project-id/todo-app/backend:latest"
frontend_image = "asia-northeast1-docker.pkg.dev/your-gcp-project-id/todo-app/frontend:latest"
```

### 3. デプロイ実行

```bash
# ルートディレクトリに戻る
cd ..

# デプロイスクリプトを実行
./scripts/deploy.sh
```

このスクリプトは以下を実行します:
1. Docker イメージをビルド
2. Artifact Registry にプッシュ
3. Terraform でインフラを構築
4. Cloud Run にデプロイ

### 4. デプロイ確認

デプロイが完了すると、URL が表示されます:

```bash
# フロントエンドURL
terraform -chdir=terraform output -raw frontend_url

# バックエンドURL
terraform -chdir=terraform output -raw backend_url
```

ブラウザでフロントエンド URL にアクセスして動作確認してください。

## CI/CD パイプライン（オプション）

### Cloud Build の設定

```bash
# Cloud Build トリガーを作成
gcloud builds submit --config cloudbuild.yaml
```

### GitHub と連携

1. GCP コンソールで Cloud Build にアクセス
2. トリガーを作成
3. GitHub リポジトリを接続
4. `cloudbuild.yaml` を指定
5. `main` ブランチへの push でビルドが自動実行されるように設定

## コスト見積もり

無料枠を超えた場合の月額概算（軽い使用量）:

- Cloud Run: ~$5-10
- Cloud SQL (db-f1-micro): ~$7-15
- VPC Connector: ~$7
- Artifact Registry: ~$0.10
- Secret Manager: ~$0.06

**合計**: ~$20-32/月

### コスト削減のヒント

1. **Cloud SQL の停止**: 使わない時は手動で停止
   ```bash
   gcloud sql instances patch todo-app-mysql --activation-policy=NEVER
   ```

2. **最小インスタンスを0に**: Cloud Run の設定で最小インスタンスを0にする（デフォルト）

3. **リージョン選択**: asia-northeast1 以外の安価なリージョンを検討

## 管理コマンド

### ログの確認

```bash
# バックエンドのログ
gcloud run logs read todo-backend --region=asia-northeast1

# フロントエンドのログ
gcloud run logs read todo-frontend --region=asia-northeast1

# Cloud SQL のログ
gcloud sql operations list --instance=todo-app-mysql
```

### データベースへの接続

```bash
# Cloud SQL Proxy を使用
cloud-sql-proxy YOUR_PROJECT_ID:asia-northeast1:todo-app-mysql
```

別のターミナルで:
```bash
mysql -h 127.0.0.1 -u todoapp_user -p todo_db
```

### リソースの削除

```bash
cd terraform
terraform destroy
```

**注意**: データベースが削除されるため、必要なデータはバックアップしてください。

## トラブルシューティング

### 1. Cloud Run サービスが起動しない

```bash
# ログを確認
gcloud run logs read todo-backend --region=asia-northeast1 --limit=50

# サービスの状態を確認
gcloud run services describe todo-backend --region=asia-northeast1
```

### 2. データベース接続エラー

- VPC Connector が正しく設定されているか確認
- Cloud SQL のプライベート IP が正しく設定されているか確認
- Secret Manager のパスワードが正しいか確認

```bash
# VPC Connector の確認
gcloud compute networks vpc-access connectors describe todo-app-connector --region=asia-northeast1

# Cloud SQL の確認
gcloud sql instances describe todo-app-mysql
```

### 3. Terraform エラー

```bash
# 状態をクリア（注意: リソースが孤立する可能性あり）
cd terraform
terraform state list
terraform state rm <resource_name>  # 問題のあるリソース

# または完全にリセット
rm -rf .terraform terraform.tfstate*
terraform init
```

### 4. Docker イメージのビルドエラー

```bash
# ローカルで本番イメージをテスト
./scripts/local-build-prod.sh

# イメージを手動でビルド
docker build -t test-backend -f backend/Dockerfile.prod ./backend
docker run -p 8080:8080 test-backend
```

## セキュリティのベストプラクティス

1. **Secret Manager を使用**: パスワードを直接コードに書かない
2. **IAM 権限を最小化**: 必要最小限の権限のみ付与
3. **VPC 内通信**: Cloud Run と Cloud SQL 間はプライベート接続
4. **HTTPS のみ**: Cloud Run は自動的に HTTPS を提供
5. **定期的な更新**: 依存関係とベースイメージを定期的に更新

## 次のステップ

1. **カスタムドメイン**: Cloud Run にカスタムドメインを設定
2. **モニタリング**: Cloud Monitoring でアラートを設定
3. **バックアップ**: Cloud SQL の自動バックアップを設定（デフォルトで有効）
4. **スケーリング**: 負荷に応じて Cloud Run のインスタンス数を調整
5. **CDN**: Cloud CDN を設定してフロントエンドを高速化

## 参考リンク

- [Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [Cloud SQL ドキュメント](https://cloud.google.com/sql/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Build ドキュメント](https://cloud.google.com/build/docs)
