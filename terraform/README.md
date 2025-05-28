# 🏗️ Terraform Infrastructure for Agentic Data Science Platform

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-7B42BC)](https://www.terraform.io/)
[![Google Cloud](https://img.shields.io/badge/Provider-Google%20Cloud-4285F4)](https://registry.terraform.io/providers/hashicorp/google/latest)
[![Infrastructure as Code](https://img.shields.io/badge/IaC-100%25-00897B)](https://en.wikipedia.org/wiki/Infrastructure_as_code)
[![ADK Ready](https://img.shields.io/badge/ADK-Ready-FF6F00)](https://google.github.io/adk-docs/)

## 📋 Overview

This directory contains the **production-ready Terraform configuration** for deploying the Agentic Data Science Platform on Google Cloud Platform. The infrastructure is designed with enterprise security, scalability, and AI integration in mind, featuring automated data pipelines, event-driven processing, and preparation for Google's Agent Development Kit (ADK).

### 🎯 Infrastructure Highlights

- **100% Infrastructure as Code** - Every resource managed through Terraform
- **Enterprise Security** - Least privilege IAM with dedicated service accounts
- **Event-Driven Architecture** - Cloud Functions Gen 2 with automatic triggers
- **State Management** - Remote state storage with versioning and locking
- **AI/ML Ready** - Pre-configured for ADK agents and Vertex AI integration
- **Zero Manual Setup** - Fully automated provisioning

## 🏛️ Architecture Components

### Core Infrastructure

| Component | Resource | Purpose |
|-----------|----------|---------|
| **Data Warehouse** | `google_bigquery_dataset` | Analytics-ready data storage |
| **Event Processing** | `google_cloudfunctions2_function` | Automated CSV ingestion |
| **Storage** | `google_storage_bucket` | Data staging & state management |
| **Networking** | VPC Connector | Secure function connectivity |
| **IAM** | Service Accounts | Granular permission control |

### ADK Integration (Pre-configured)

| Component | Resource | Purpose |
|-----------|----------|---------|
| **ADK Artifacts** | `google_storage_bucket.adk_artifacts` | Agent code storage |
| **Agent Service Accounts** | Multiple SAs | Dedicated agent permissions |
| **Vertex AI APIs** | `aiplatform.googleapis.com` | ML/AI capabilities |
| **AutoML Access** | BigQuery ML permissions | Automated model training |

## 📁 File Structure

```
terraform/
├── main.tf                 # Core infrastructure resources
├── permissions.tf          # IAM policies and bindings
├── cloud_function.tf       # Cloud Function Gen 2 configuration
├── variables.tf           # Input variable definitions
├── backend.tf             # State management configuration
├── terraform.tfvars.example # Example variable values
└── function/              # Cloud Function source code
    ├── main.py           # CSV processing logic
    └── requirements.txt   # Python dependencies
```

## 🚀 Quick Start

### Prerequisites

- Google Cloud Project with billing enabled
- Terraform >= 1.0
- Google Cloud SDK (`gcloud`)
- Appropriate IAM permissions

### Deployment Steps

1. **Clone and Navigate**
   ```bash
   git clone https://github.com/JeanFraga/agentic-data-science.git
   cd agentic-data-science/terraform
   ```

2. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review Plan**
   ```bash
   terraform plan -out=tfplan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply tfplan
   ```

## 🔧 Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_id` | GCP Project ID | `my-data-science-123` |
| `region` | Deployment region | `us-central1` |
| `environment` | Environment tag | `dev`, `prod` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `bigquery_dataset_id` | BigQuery dataset name | `titanic_dataset` |
| `storage_bucket_prefix` | Bucket naming prefix | `${project_id}` |
| `enable_apis` | Auto-enable GCP APIs | `true` |

## 🏗️ Resources Created

### Storage Resources
- **Terraform State Bucket** - Versioned state storage with lifecycle policies
- **Terraform Plans Bucket** - Historical plan storage (30-day retention)
- **Data Ingestion Bucket** - CSV upload trigger point
- **Function Source Bucket** - Cloud Function deployment artifacts
- **ADK Artifacts Bucket** - Agent code and configurations

### Compute Resources
- **Cloud Function Gen 2** - Event-driven CSV processor
  - Memory: 256MB
  - Timeout: 300s
  - Min Instances: 0 (scales to zero)
  - Max Instances: 10

### Data Resources
- **BigQuery Dataset** - `titanic_dataset` with 30-day table expiration
- **BigQuery Table** - Auto-created schema for Titanic data

### Security Resources
- **Service Accounts**:
  - `cloud-function-sa` - Function execution
  - `bigquery-sa` - Data operations
  - `adk-agent-sa` - ADK agent operations
  - `bqml-agent-sa` - BigQuery ML operations
  - `vertex-agent-sa` - Vertex AI operations

### Networking
- **VPC Connector** - Secure egress for Cloud Functions
- **Eventarc Trigger** - Storage event processing

## 🔐 Security Features

### IAM Implementation
- **Least Privilege Model** - Only required permissions granted
- **Service Account Separation** - Dedicated accounts per service
- **No User Permissions** - All access via service accounts
- **Audit Logging** - Complete operation tracking

### Example IAM Binding
```hcl
resource "google_project_iam_member" "function_bigquery_access" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
}
```

## 🤖 ADK Integration Points

The infrastructure is pre-configured for ADK agent integration:

### 1. **BigQuery Access**
```hcl
# ADK agents can query and create models
resource "google_project_iam_member" "adk_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.adk_agent.email}"
}
```

### 2. **Vertex AI Integration**
```hcl
# Enabled APIs for AI/ML operations
resource "google_project_service" "vertex_ai" {
  service = "aiplatform.googleapis.com"
}
```

### 3. **AutoML Permissions**
```hcl
# BigQuery ML model creation
resource "google_project_iam_member" "bqml_model_creator" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.bqml_agent.email}"
}
```

## 📊 Outputs

After deployment, Terraform provides these outputs:

```hcl
# Storage locations
bucket_name = "project-123-data-ingestion"
function_bucket = "project-123-cloud-functions"
adk_artifacts_bucket = "project-123-adk-artifacts"

# Service endpoints
function_url = "https://function-xyz.cloudfunctions.net"
bigquery_dataset = "project-123:titanic_dataset"

# Service account emails
cloud_function_sa = "cloud-function-sa@project-123.iam.gserviceaccount.com"
adk_agent_sa = "adk-agent-sa@project-123.iam.gserviceaccount.com"
```

## 🔄 State Management

### Remote State Configuration
```hcl
terraform {
  backend "gcs" {
    bucket = "your-project-terraform-state"
    prefix = "agentic-data-science/terraform"
  }
}
```

### State Security
- **Versioning Enabled** - Rollback capability
- **Uniform Access** - No ACLs, only IAM
- **Encryption** - Google-managed encryption
- **Locking** - Prevents concurrent modifications

## 🧪 Testing

### Local Validation
```bash
# Format check
terraform fmt -check

# Validation
terraform validate

# Security scan
tfsec .
```

### Infrastructure Tests
```bash
# Plan review
terraform plan -detailed-exitcode

# Dry run
terraform apply -auto-approve=false
```

## 📈 Cost Optimization

### Resource Sizing
- Cloud Functions scale to zero when idle
- BigQuery uses on-demand pricing
- Storage lifecycle policies remove old data
- VPC Connector uses minimum machine type

### Estimated Monthly Costs
- **Minimal Usage**: ~$5-10
- **Moderate Usage**: ~$50-100
- **Heavy Usage**: ~$200-500

*Costs vary based on data volume and processing frequency*

## 🛠️ Maintenance

### Updating Infrastructure
```bash
# Pull latest changes
git pull origin main

# Review changes
terraform plan

# Apply updates
terraform apply
```

### Destroying Resources
```bash
# Complete teardown
terraform destroy

# Selective removal
terraform destroy -target=google_storage_bucket.data_ingestion
```

## 🐛 Troubleshooting

### Common Issues

1. **API Not Enabled**
   ```bash
   Error: googleapi: Error 403: API not enabled
   Solution: Terraform auto-enables APIs, wait and retry
   ```

2. **Permission Denied**
   ```bash
   Error: Permission denied on resource
   Solution: Verify service account has required roles
   ```

3. **State Lock**
   ```bash
   Error: Error acquiring the state lock
   Solution: terraform force-unlock <lock-id>
   ```

## 📚 Additional Resources

- [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Functions Gen 2 Guide](https://cloud.google.com/functions/docs/2nd-gen/overview)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [ADK Documentation](https://google.github.io/adk-docs/)

## 🤝 Contributing

1. Create feature branch
2. Make infrastructure changes
3. Run `terraform fmt` and `terraform validate`
4. Submit PR with plan output

---

**Created by**: Jean Fraga  
**Part of**: [Agentic Data Science Platform](https://github.com/JeanFraga/agentic-data-science)

*This infrastructure represents modern cloud engineering best practices, ready for AI-powered data science workflows.*