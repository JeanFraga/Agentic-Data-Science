# create bigquery dataset
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
    "serviceusage.googleapis.com"
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
  
  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }
    # Enable versioning for state file history
  versioning {
    enabled = true
  }
  
  # Enable uniform bucket-level access
  uniform_bucket_level_access = true
  
  labels = {
    environment = var.environment
    purpose     = "terraform-state"
  }
  
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