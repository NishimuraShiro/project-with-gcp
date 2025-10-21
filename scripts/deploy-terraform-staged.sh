#!/bin/bash
set -e

cd terraform

echo "=== Stage 1: ネットワークとデータベースをデプロイ ==="
terraform apply -auto-approve \
  -target=google_project_service.sqladmin \
  -target=google_project_service.servicenetworking \
  -target=google_project_service.vpcaccess \
  -target=google_project_service.secretmanager \
  -target=google_compute_network.vpc \
  -target=google_compute_subnetwork.subnet \
  -target=google_compute_global_address.private_ip_address \
  -target=google_service_networking_connection.private_vpc_connection \
  -target=google_sql_database_instance.main \
  -target=google_sql_database.database \
  -target=google_sql_user.user \
  -target=google_secret_manager_secret.db_password \
  -target=google_secret_manager_secret_version.db_password

echo ""
echo "=== Stage 2: VPC Connectorをデプロイ（5分程度かかります） ==="
terraform apply -auto-approve \
  -target=google_vpc_access_connector.connector

echo ""
echo "=== Stage 3: Cloud Runサービスをデプロイ ==="
terraform apply -auto-approve

cd ..

echo ""
echo "=== デプロイ完了 ==="
terraform -chdir=terraform output
