# create bigquery dataset
provider "google" {
  project = var.project_id
  region  = var.region
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
}