# CI/CD セットアップガイド

GitHub Actionsを使用して、mainブランチへのプッシュで自動的にCloud Runへデプロイする仕組みを構築します。

## 前提条件

- GitHubリポジトリが作成済み
- GCPプロジェクトが設定済み
- ローカルで一度デプロイが成功している

## セットアップ手順

### 1. GCPサービスアカウントの作成

プロジェクトのルートディレクトリで以下を実行：

```bash
./scripts/setup-github-actions.sh
```

このスクリプトは以下を実行します：
- GitHub Actions専用のサービスアカウントを作成
- 必要な権限（Cloud Run管理者、Artifact Registry書き込みなど）を付与
- 認証キーを生成
- GitHubに設定すべきシークレットの値を表示

### 2. GitHub Secretsの設定

1. GitHubリポジトリにアクセス
2. **Settings** > **Secrets and variables** > **Actions** を開く
3. **New repository secret** をクリック
4. 以下のシークレットを追加：

| Name | Description | Example Value |
|------|-------------|---------------|
| `GCP_PROJECT_ID` | GCPプロジェクトID | `project-a98a4810-1025-412c-880` |
| `GCP_SA_KEY` | サービスアカウントキー（Base64エンコード済み） | スクリプト出力からコピー |
| `BACKEND_IMAGE_NAME` | バックエンドイメージの完全なパス | `asia-northeast1-docker.pkg.dev/PROJECT_ID/todo-app/backend` |
| `FRONTEND_IMAGE_NAME` | フロントエンドイメージの完全なパス | `asia-northeast1-docker.pkg.dev/PROJECT_ID/todo-app/frontend` |
| `REGION` | デプロイ先のリージョン | `asia-northeast1` |

**重要**: `GCP_SA_KEY` の値は、スクリプトが出力するBase64エンコードされた文字列全体をコピーしてください。

### 3. ワークフローの確認

`.github/workflows/deploy.yml` が作成されています。このワークフローは：

1. **トリガー**: mainブランチへのpush時に自動実行
2. **ビルド**: Docker イメージをAMD64アーキテクチャでビルド
3. **プッシュ**: Artifact Registryにプッシュ
4. **デプロイ**: Cloud Runへデプロイ（バックエンド → フロントエンド）
5. **サマリー**: デプロイ結果とURLを表示

### 4. テスト

簡単な変更をコミットしてプッシュ：

```bash
# 小さな変更を加える
echo "# CI/CD Test" >> README.md

# コミット
git add .
git commit -m "test: CI/CD pipeline"

# プッシュ（自動デプロイがトリガーされる）
git push origin main
```

### 5. デプロイの確認

1. GitHubリポジトリの **Actions** タブを開く
2. 実行中のワークフローをクリック
3. 各ステップの進行状況を確認
4. 完了後、Summary にデプロイされたURLが表示される

## ワークフローの詳細

### トリガー条件

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch: # 手動実行も可能
```

- mainブランチへのpush時に自動実行
- GitHub UIから手動でも実行可能

### ビルドプロセス

```yaml
- docker buildx build --platform linux/amd64 ...
```

- **重要**: Cloud RunはAMD64アーキテクチャが必要
- M1/M2 Macでも正しくビルドされるよう `--platform` を指定

### デプロイ順序

1. **バックエンド**を先にデプロイ
2. バックエンドのURLを取得
3. **フロントエンド**をデプロイ（環境変数にバックエンドURLを設定）

これにより、フロントエンドが常に正しいバックエンドURLを参照します。

## トラブルシューティング

### 権限エラー

```
ERROR: (gcloud.run.deploy) PERMISSION_DENIED
```

**解決策**: サービスアカウントに必要な権限があるか確認

```bash
# 権限を確認
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deploy@*"
```

### イメージプッシュ失敗

```
denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
```

**解決策**: Artifact Registryへの書き込み権限を確認

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:github-actions-deploy@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

### ビルドタイムアウト

**解決策**: ワークフローの `timeout-minutes` を調整

```yaml
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # デフォルトは360分
```

### デプロイ後にアプリが動作しない

**チェックリスト**:
1. Cloud Runのログを確認
   ```bash
   gcloud run services logs read todo-backend --region=asia-northeast1 --limit=50
   ```
2. 環境変数が正しく設定されているか確認
3. データベース接続設定を確認

## 手動デプロイ

CI/CDとは別に、手動でデプロイすることも可能：

```bash
# ローカルから手動デプロイ
./scripts/deploy.sh
```

## セキュリティのベストプラクティス

1. **サービスアカウントキーの管理**
   - キーファイル（`github-actions-key.json`）はGitHubに設定後、ローカルから削除
   - 定期的にキーをローテーション

2. **最小権限の原則**
   - サービスアカウントには必要最小限の権限のみ付与
   - 本番環境とステージング環境で別のサービスアカウントを使用

3. **シークレットの保護**
   - GitHub Secretsは暗号化されて保存される
   - ワークフローログにシークレットは表示されない

## 参考リンク

- [GitHub Actions ドキュメント](https://docs.github.com/en/actions)
- [Google Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [Workload Identity Federation（より安全な認証方法）](https://cloud.google.com/iam/docs/workload-identity-federation)
