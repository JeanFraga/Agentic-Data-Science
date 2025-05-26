# Terraform configuration for Google Cloud Platform (GCP)
# This configuration sets up the necessary resources and permissions for the Agentic Data Science project.
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs first
resource "google_project_service" "required_apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "storage.googleapis.com", 
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "eventarc.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "artifactregistry.googleapis.com",
    # ADK and Vertex AI APIs
    "aiplatform.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Cloud Storage bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-terraform-state"
  location = var.region
  
  # Enable versioning for state file safety
  versioning {
    enabled = true
  }
  
  # Lifecycle management for state files
  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }
  
  # Security settings
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  depends_on = [google_project_service.required_apis]
}

# Cloud Storage bucket for Terraform plan files
resource "google_storage_bucket" "terraform_plans" {
  name     = "${var.project_id}-terraform-plans"
  location = var.region
  
  # Enable versioning for plan file history
  versioning {
    enabled = true
  }
  
  # Lifecycle management for plan files (shorter retention)
  lifecycle_rule {
    condition {
      age = 30  # Delete plan files older than 30 days
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      num_newer_versions = 5  # Keep only 5 versions of each plan
    }
    action {
      type = "Delete"
    }
  }
  
  # Security settings
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  depends_on = [google_project_service.required_apis]
}

resource "google_bigquery_dataset" "test_dataset" {
  dataset_id = "test_dataset"
  friendly_name = "test_dataset"
  location   = var.region
  description = "Dataset for ${var.project_id}"
  labels = {
    environment = var.environment
    project     = var.project_id
  }
  
  depends_on = [google_project_service.required_apis]
}

# create a cloud storage bucket for temporary data
resource "google_storage_bucket" "temp_bucket" {
  name     = "${var.project_id}-temp-bucket"
  location = var.region
  labels = {
    environment = var.environment
    project     = var.project_id
  }
  
  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# ADK (Agent Development Kit) Infrastructure
# ==============================================================================

# BigQuery dataset for Titanic data
resource "google_bigquery_dataset" "titanic_dataset" {
  dataset_id                  = var.dataset_id
  friendly_name              = "Titanic Dataset"
  location                   = var.bq_location
  description                = "Dataset for Titanic survival prediction analysis using ADK agents"
  default_table_expiration_ms = null
  
  labels = {
    environment = var.environment
    project     = var.project_id
    dataset_type = "ml_training"
    agent_project = "titanic_survival"
  }
  
  access {
    role          = "OWNER"
    user_by_email = data.google_client_openid_userinfo.me.email
  }
  
  access {
    role         = "READER"
    special_group = "projectReaders"
  }
  
  access {
    role         = "WRITER"
    special_group = "projectWriters"
  }
  
  # Grant BigQuery ML Agent admin access
  access {
    role          = "OWNER"
    user_by_email = google_service_account.bqml_agent.email
  }
  
  # Grant ADK Agent read access
  access {
    role          = "READER"
    user_by_email = google_service_account.adk_agent.email
  }
  
  # Grant Vertex AI Agent read access
  access {
    role          = "READER" 
    user_by_email = google_service_account.vertex_agent.email
  }
  
  depends_on = [
    google_project_service.required_apis,
    google_service_account.adk_agent,
    google_service_account.bqml_agent,
    google_service_account.vertex_agent
  ]
}

# Secret Manager secret for Gemini API key
resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "gemini-api-key"
  
  labels = {
    environment = var.environment
    service     = "adk_agents"
  }
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.required_apis]
}

# Secret version for Gemini API key
resource "google_secret_manager_secret_version" "gemini_api_key_version" {
  secret      = google_secret_manager_secret.gemini_api_key.id
  secret_data = var.gemini_api_key
  
  depends_on = [google_secret_manager_secret.gemini_api_key]
}

# Grant ADK agents access to the Gemini API key secret
resource "google_secret_manager_secret_iam_member" "adk_agent_secret_access" {
  secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.adk_agent.email}"
  
  depends_on = [
    google_secret_manager_secret.gemini_api_key,
    google_service_account.adk_agent
  ]
}

resource "google_secret_manager_secret_iam_member" "vertex_agent_secret_access" {
  secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vertex_agent.email}"
  
  depends_on = [
    google_secret_manager_secret.gemini_api_key,
    google_service_account.vertex_agent
  ]
}

# Storage bucket for ADK agent packages and artifacts
resource "google_storage_bucket" "adk_artifacts" {
  name     = "${var.project_id}-adk-artifacts"
  location = var.region
  
  labels = {
    environment = var.environment
    service     = "adk_agents"
    purpose     = "agent_packages"
  }
  
  # Security settings
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  # Lifecycle management
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  depends_on = [google_project_service.required_apis]
}

# Grant storage access to ADK service accounts
resource "google_storage_bucket_iam_member" "adk_agent_storage_access" {
  bucket = google_storage_bucket.adk_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.adk_agent.email}"
  
  depends_on = [
    google_storage_bucket.adk_artifacts,
    google_service_account.adk_agent
  ]
}

# Data source to get current user info for BigQuery dataset access
data "google_client_openid_userinfo" "me" {
}

# ==============================================================================
# Outputs for ADK Infrastructure
# ==============================================================================

output "titanic_dataset_id" {
  description = "BigQuery dataset ID for Titanic data"
  value       = google_bigquery_dataset.titanic_dataset.dataset_id
}

output "titanic_dataset_location" {
  description = "BigQuery dataset location"
  value       = google_bigquery_dataset.titanic_dataset.location
}

output "gemini_api_key_secret_name" {
  description = "Secret Manager secret name for Gemini API key"
  value       = google_secret_manager_secret.gemini_api_key.secret_id
}

output "adk_artifacts_bucket" {
  description = "Storage bucket for ADK artifacts"
  value       = google_storage_bucket.adk_artifacts.name
}

output "adk_artifacts_bucket_url" {
  description = "Storage bucket URL for ADK artifacts"
  value       = google_storage_bucket.adk_artifacts.url
}

# Service account keys should be generated separately for security
output "service_account_key_generation_commands" {
  description = "Commands to generate service account keys for local development"
  value = {
    adk_agent = "gcloud iam service-accounts keys create adk-agent-key.json --iam-account=${google_service_account.adk_agent.email}"
    bqml_agent = "gcloud iam service-accounts keys create bqml-agent-key.json --iam-account=${google_service_account.bqml_agent.email}"
    vertex_agent = "gcloud iam service-accounts keys create vertex-agent-key.json --iam-account=${google_service_account.vertex_agent.email}"
  }
}