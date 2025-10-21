#!/bin/bash
set -e

cd terraform

PROJECT_ID=$(gcloud config get-value project)
REGION="asia-northeast1"

echo "=== 既存のGCPリソースをTerraformにインポート ==="
echo "プロジェクトID: $PROJECT_ID"
echo ""

# 既にインポート済みのリソースはスキップされる

# VPC Network
echo "VPC Networkをインポート中..."
terraform import google_compute_network.vpc projects/$PROJECT_ID/global/networks/todo-app-vpc 2>/dev/null || echo "Already imported or not exists"

# Subnet
echo "Subnetをインポート中..."
terraform import google_compute_subnetwork.subnet projects/$PROJECT_ID/regions/$REGION/subnetworks/todo-app-subnet 2>/dev/null || echo "Already imported or not exists"

# VPC Access Connector
echo "VPC Access Connectorをインポート中..."
terraform import google_vpc_access_connector.connector projects/$PROJECT_ID/locations/$REGION/connectors/todo-app-connector 2>/dev/null || echo "Already imported or not exists"

# Global Address
echo "Global Addressをインポート中..."
terraform import google_compute_global_address.private_ip_address projects/$PROJECT_ID/global/addresses/todo-app-private-ip 2>/dev/null || echo "Already imported or not exists"

# Service Networking Connection
echo "Service Networking Connectionをインポート中..."
terraform import google_service_networking_connection.private_vpc_connection projects/$PROJECT_ID/global/networks/todo-app-vpc:servicenetworking.googleapis.com 2>/dev/null || echo "Already imported or not exists"

# Secret Manager Secret
echo "Secret Manager Secretをインポート中..."
terraform import google_secret_manager_secret.db_password projects/$PROJECT_ID/secrets/db-password 2>/dev/null || echo "Already imported"

# Cloud SQL Instance
echo "Cloud SQL Instanceをインポート中..."
terraform import google_sql_database_instance.main projects/$PROJECT_ID/instances/todo-app-mysql 2>/dev/null || echo "Already imported or not exists"

# Cloud SQL Database
echo "Cloud SQL Databaseをインポート中..."
terraform import google_sql_database.database projects/$PROJECT_ID/instances/todo-app-mysql/databases/todo_db 2>/dev/null || echo "Already imported or not exists"

# Cloud SQL User
echo "Cloud SQL Userをインポート中..."
terraform import google_sql_user.user projects/$PROJECT_ID/instances/todo-app-mysql/todoapp_user 2>/dev/null || echo "Already imported or not exists"

# Cloud Run Services
echo "Cloud Run Backend Serviceをインポート中..."
terraform import google_cloud_run_service.backend locations/$REGION/namespaces/$PROJECT_ID/services/todo-backend 2>/dev/null || echo "Already imported or not exists"

echo "Cloud Run Frontend Serviceをインポート中..."
terraform import google_cloud_run_service.frontend locations/$REGION/namespaces/$PROJECT_ID/services/todo-frontend 2>/dev/null || echo "Already imported or not exists"

echo ""
echo "=== インポート完了 ==="
echo "次のコマンドでデプロイを続行してください:"
echo "  cd .. && ./scripts/deploy.sh"
