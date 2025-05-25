variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "us-east1"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
  default     = "JeanFraga"
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "agentic-data-science"
}

variable "deployment_branch" {
  description = "Git branch to deploy from"
  type        = string
  default     = "main"
}

variable "gemini_api_key" {
  description = "Google Gemini API key for natural language processing"
  type        = string
  sensitive   = true
}