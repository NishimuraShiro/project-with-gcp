# Artifact Registry Repository
# Note: Repository is created by setup-gcp.sh script
# Using data source instead of resource to reference existing repository

data "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "todo-app"
}
