# Cloud Run Service - Backend
resource "google_cloud_run_service" "backend" {
  name     = "todo-backend"
  location = var.region

  template {
    spec {
      containers {
        image = var.backend_image

        ports {
          container_port = 8080
        }

        startup_probe {
          http_get {
            path = "/health"
            port = 8080
          }
          initial_delay_seconds = 10
          timeout_seconds       = 5
          period_seconds        = 10
          failure_threshold     = 3
        }

        liveness_probe {
          http_get {
            path = "/health"
            port = 8080
          }
          initial_delay_seconds = 30
          timeout_seconds       = 5
          period_seconds        = 30
        }

        env {
          name  = "NODE_ENV"
          value = "production"
        }

        env {
          name  = "DB_HOST"
          value = google_sql_database_instance.main.private_ip_address
        }

        env {
          name  = "DB_USER"
          value = var.db_user
        }

        env {
          name = "DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_password.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "DB_NAME"
          value = var.db_name
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }

      container_concurrency = 80
      timeout_seconds       = 300
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "10"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.id
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloudrun,
    google_sql_database_instance.main
  ]
}

# Cloud Run Service - Frontend
resource "google_cloud_run_service" "frontend" {
  name     = "todo-frontend"
  location = var.region

  template {
    spec {
      containers {
        image = var.frontend_image

        env {
          name  = "NEXT_PUBLIC_API_URL"
          value = google_cloud_run_service.backend.status[0].url
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }

      container_concurrency = 80
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloudrun,
    google_cloud_run_service.backend
  ]
}

# IAM policy to allow unauthenticated access to backend
resource "google_cloud_run_service_iam_member" "backend_noauth" {
  service  = google_cloud_run_service.backend.name
  location = google_cloud_run_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM policy to allow unauthenticated access to frontend
resource "google_cloud_run_service_iam_member" "frontend_noauth" {
  service  = google_cloud_run_service.frontend.name
  location = google_cloud_run_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
