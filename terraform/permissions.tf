# Complete IAM configuration as code for Agentic Data Science project
# This file manages all service accounts and IAM permissions

# Service Account for GitHub Actions (Terraform deployments)
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-terraform"
  display_name = "GitHub Actions Terraform Service Account"
  description  = "Service account for GitHub Actions to manage Terraform infrastructure"
  project      = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Service Account for Cloud Function (Data processing)
resource "google_service_account" "cloud_function" {
  account_id   = "cloud-function-bigquery"
  display_name = "Cloud Function BigQuery Service Account"
  description  = "Service account for Cloud Function to process data and load into BigQuery"
  project      = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# IAM roles for GitHub Actions service account (Infrastructure management)
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/bigquery.admin",
    "roles/storage.admin",
    "roles/cloudfunctions.admin", 
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/eventarc.admin",
    "roles/run.admin",
    "roles/pubsub.admin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
  
  depends_on = [google_service_account.github_actions]
}

# Specific permissions for GitHub Actions to access plan bucket
resource "google_storage_bucket_iam_member" "github_actions_plans_access" {
  bucket = google_storage_bucket.terraform_plans.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_actions.email}"
  
  depends_on = [
    google_service_account.github_actions,
    google_storage_bucket.terraform_plans
  ]
}

# IAM roles for Cloud Function service account (Data operations)
resource "google_project_iam_member" "cloud_function_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.user",
    "roles/storage.objectViewer",
    "roles/run.invoker",
    "roles/eventarc.eventReceiver"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
  
  depends_on = [google_service_account.cloud_function]
}

# Cloud Storage service account permissions for Gen 2 Cloud Functions
# Required for GCS CloudEvent triggers to publish to Pub/Sub
resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-435563057240@gs-project-accounts.iam.gserviceaccount.com"
  
  depends_on = [google_project_service.required_apis]
}

# Note: Service account key should be generated manually or via gcloud CLI
# to avoid permission issues during initial setup. The key is already
# available in github-actions-key.json from previous successful run.

# Output service account information
output "github_actions_service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "cloud_function_service_account_email" {
  description = "Email of the Cloud Function service account"
  value       = google_service_account.cloud_function.email
}

output "terraform_state_bucket" {
  description = "GCS bucket for Terraform state files"
  value       = google_storage_bucket.terraform_state.name
}

output "terraform_plans_bucket" {
  description = "GCS bucket for Terraform plan files"
  value       = google_storage_bucket.terraform_plans.name
}

# Note: github-actions-key.json already exists from previous successful deployment
# Update the GitHub secret GCP_SERVICE_ACCOUNT_KEY with the content of that file