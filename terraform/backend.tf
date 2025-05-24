terraform {
  backend "gcs" {
    bucket = "agentic-data-science-460701-terraform-state"
    prefix = "terraform/state"
  }
}
