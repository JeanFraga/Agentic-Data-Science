# Cloud Function Gen 2 for automatic BigQuery data loading
resource "google_cloudfunctions2_function" "titanic_data_loader" {
  name        = "titanic-data-loader"
  location    = var.region
  description = "Automatically loads titanic.csv files to BigQuery when uploaded to temp bucket"

  build_config {
    runtime     = "python311"
    entry_point = "load_titanic_to_bigquery"
    
    # Use GitHub repository source for maintainable deployments
    source {
      repo_source {
        project_id   = var.project_id
        repo_name    = var.github_repo_name
        branch_name  = "main"
        dir          = "cloud_function_src"
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

# Cloud Function Gen 2 for Agent SDK HTTP API
resource "google_cloudfunctions2_function" "agent_sdk_api" {
  name        = "agent-sdk-api"
  location    = var.region
  description = "HTTP API for Agent SDK natural language ML interactions"

  build_config {
    runtime     = "python311"
    entry_point = "main"
    
    # Use GitHub repository source for maintainable deployments
    source {
      repo_source {
        project_id   = var.project_id
        repo_name    = var.github_repo_name
        branch_name  = "main"
        dir          = "cloud_function_src"
      }
    }
  }

  service_config {
    max_instance_count    = 100
    min_instance_count    = 0
    available_memory      = "512M"
    timeout_seconds       = 300
    service_account_email = google_service_account.cloud_function.email
    
    environment_variables = {
      PROJECT_ID    = var.project_id
      DATASET_ID    = "test_dataset"
      GEMINI_API_KEY = var.gemini_api_key
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.cloud_function,
    google_project_iam_member.cloud_function_roles
  ]
}
