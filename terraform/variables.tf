variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "todoapp_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "todo_db"
}

variable "backend_image" {
  description = "Backend Docker image URL"
  type        = string
}

variable "frontend_image" {
  description = "Frontend Docker image URL"
  type        = string
}
