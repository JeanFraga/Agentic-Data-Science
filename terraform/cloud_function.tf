# Cloud Function for automatic BigQuery data loading
resource "google_cloudfunctions2_function" "titanic_data_loader" {
  name        = "titanic-data-loader"
  location    = var.region
  description = "Automatically loads titanic.csv files to BigQuery when uploaded to temp bucket"

  build_config {
    runtime     = "python311"
    entry_point = "load_titanic_to_bigquery"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source_zip.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "256M"
    timeout_seconds    = 300
    environment_variables = {
      PROJECT_ID = var.project_id
      DATASET_ID = "test_dataset"
      TABLE_ID   = "titanic"
    }
    service_account_email = google_service_account.function_sa.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_RETRY"
    
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.temp_bucket.name
    }
    
    event_filters {
      attribute = "name"
      value     = "titanic.csv"
    }
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.eventarc,
    google_project_service.run,
    google_project_service.pubsub
  ]
}

# Service account for the Cloud Function
resource "google_service_account" "function_sa" {
  account_id   = "titanic-loader-sa"
  display_name = "Titanic Data Loader Service Account"
  description  = "Service account for the Titanic data loader Cloud Function"
}

# IAM bindings for the service account
resource "google_project_iam_member" "function_sa_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_sa_storage_reader" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# Enable required APIs
resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "eventarc" {
  service = "eventarc.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "pubsub" {
  service = "pubsub.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "bigquery" {
  service = "bigquery.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "storage" {
  service = "storage.googleapis.com"
  project = var.project_id
}

# Bucket for function source code
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-function-source"
  location = var.region
  
  uniform_bucket_level_access = true
  
  labels = {
    environment = var.environment
    purpose     = "cloud-function-source"
  }
}

# Create zip file with function code
data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/function-source.zip"
  source_dir  = "${path.module}/function"
}

# Upload function source code
resource "google_storage_bucket_object" "function_source_zip" {
  name   = "function-source-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_zip.output_path
}
