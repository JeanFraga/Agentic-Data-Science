# Cloud Function for automatic BigQuery data loading
resource "google_cloudfunctions_function" "titanic_data_loader" {
  name                  = "titanic-data-loader"
  location              = var.region
  description           = "Automatically loads titanic.csv files to BigQuery when uploaded to temp bucket"
  runtime               = "python311"
  available_memory_mb   = 256
  timeout               = 300
  entry_point           = "load_titanic_to_bigquery"
  service_account_email = google_service_account.cloud_function.email

  environment_variables = {
    PROJECT_ID = var.project_id
    DATASET_ID = "test_dataset"
    TABLE_ID   = "titanic"
  }

  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_source_zip.name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.temp_bucket.name
    
    failure_policy {
      retry = true
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.cloud_function,
    google_project_iam_member.cloud_function_roles
  ]
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
  
  depends_on = [google_project_service.required_apis]
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
