terraform {
  backend "gcs" {
    # bucket will be configured via -backend-config in GitHub Actions
    # or terraform init -backend-config="bucket=PROJECT_ID-terraform-state"
    prefix = "terraform/state"
  }
}
