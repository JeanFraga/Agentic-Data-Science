# Cloud Function Gen 2 for automatic BigQuery data loading
resource "google_cloudfunctions2_function" "titanic_data_loader" {
  name        = "titanic-data-loader"
  location    = var.region
  description = "Automatically loads titanic.csv files to BigQuery when uploaded to temp bucket"

  build_config {
    runtime     = "python311"
    entry_point = "load_titanic_to_bigquery"
    
    # Use local source for now - GitHub deployment requires manual setup
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 100
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 300
    service_account_email = google_service_account.cloud_function.email
    
    environment_variables = {
      PROJECT_ID = var.project_id
      DATASET_ID = "test_dataset"
      TABLE_ID   = "titanic"
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_RETRY"
    
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.temp_bucket.name
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.cloud_function,
    google_project_iam_member.cloud_function_roles
  ]
}

# Storage bucket for function source code
resource "google_storage_bucket" "function_source" {
  name                        = "${var.project_id}-function-source"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  labels = {
    environment = var.environment
    purpose     = "cloud-function-source"
  }
}

# Create zip file of function source
data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/function-source.zip"
  source_dir  = "${path.module}/function"
}

# Upload function source to storage
resource "google_storage_bucket_object" "function_source_zip" {
  name   = "function-source-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_zip.output_path
}
