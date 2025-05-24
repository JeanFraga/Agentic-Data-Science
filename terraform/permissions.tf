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

# IAM roles for Cloud Function service account (Data operations)
resource "google_project_iam_member" "cloud_function_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.user",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
  
  depends_on = [google_service_account.cloud_function]
}

# Additional specific permissions for Cloud Function to create tables
resource "google_project_iam_member" "cloud_function_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
  
  depends_on = [google_service_account.cloud_function]
}

# Generate service account key for GitHub Actions (initial setup only)
resource "google_service_account_key" "github_actions_key" {
  service_account_id = google_service_account.github_actions.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  
  depends_on = [
    google_service_account.github_actions,
    google_project_iam_member.github_actions_roles
  ]
}

# Output service account information
output "github_actions_service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "cloud_function_service_account_email" {
  description = "Email of the Cloud Function service account"
  value       = google_service_account.cloud_function.email
}

output "github_actions_service_account_key" {
  description = "Private key for GitHub Actions service account (base64 encoded)"
  value       = google_service_account_key.github_actions_key.private_key
  sensitive   = true
}

# Save the key to a local file for GitHub secret setup
resource "local_file" "github_actions_key_file" {
  content  = base64decode(google_service_account_key.github_actions_key.private_key)
  filename = "${path.module}/../github-actions-key.json"
  
  provisioner "local-exec" {
    command = "Write-Host 'GitHub Actions service account key saved to github-actions-key.json' -ForegroundColor Green"
    interpreter = ["powershell", "-Command"]
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "Remove-Item -Path '${path.module}/../github-actions-key.json' -Force -ErrorAction SilentlyContinue"
    interpreter = ["powershell", "-Command"]
  }
}