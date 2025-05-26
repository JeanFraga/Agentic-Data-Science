# 🚀 ADK Infrastructure Deployment Guide

## Overview
This guide walks through deploying the Agent Development Kit (ADK) infrastructure using Terraform. The infrastructure includes service accounts, BigQuery dataset, Secret Manager, and all necessary IAM permissions for ADK agents.

## Prerequisites

### 1. Get Your Free Gemini API Key
1. Visit **Google AI Studio**: https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click **"Get API Key"** 
4. Copy the generated API key (you'll need this for deployment)

> **Note**: The Gemini API is currently free with up to 60 requests per minute, no billing required!

### 2. Verify Google Cloud Setup
```bash
# Ensure you're authenticated
gcloud auth list

# Set your project
gcloud config set project {your-project-id}

# Verify project is active
gcloud config get-value project
```

## Deployment Options

### Option 1: PowerShell Setup Script (Recommended)

Use the automated setup script for streamlined deployment:

```powershell
# Navigate to the project directory
cd "path\to\your\agentic-data-science"

# Run the setup script
.\scripts\setup-adk-terraform.ps1 -ProjectId "{your-project-id}" -GeminiApiKey "YOUR_GEMINI_API_KEY"

# Optional: Plan-only mode to review changes first
.\scripts\setup-adk-terraform.ps1 -ProjectId "{your-project-id}" -GeminiApiKey "YOUR_GEMINI_API_KEY" -PlanOnly

# Optional: Generate service account keys for local development
.\scripts\setup-adk-terraform.ps1 -ProjectId "{your-project-id}" -GeminiApiKey "YOUR_GEMINI_API_KEY" -GenerateKeys
```

### Option 2: Manual Terraform Deployment

If you prefer manual control:

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (if not already done)
terraform init

# Plan the deployment (replace YOUR_GEMINI_API_KEY)
terraform plan -var="gemini_api_key=YOUR_GEMINI_API_KEY"

# Apply the configuration
terraform apply -var="gemini_api_key=YOUR_GEMINI_API_KEY"
```

### Option 3: GitHub Actions Deployment

For automated CI/CD deployment:

1. **Add GitHub Secrets**:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add these secrets:
     - `GEMINI_API_KEY`: Your Gemini API key from Google AI Studio
     - Ensure existing secrets are configured:
       - `GCP_PROJECT_ID`: {your-project-id}
       - `GCP_REGION`: us-east1
       - `GCP_ENVIRONMENT`: dev
       - `GCP_SERVICE_ACCOUNT_KEY`: GitHub Actions service account key

2. **Trigger Deployment**:
   ```bash
   git add .
   git commit -m "Deploy ADK infrastructure with Gemini API integration"
   git push origin main
   ```

## What Gets Deployed

### 🔐 Service Accounts
- **ADK Agent Service Account** (`adk-agent-sa@{project-id}.iam.gserviceaccount.com`)
  - For agent execution and orchestration
  - Permissions: BigQuery viewer, Storage viewer, AI Platform user, logging

- **BigQuery ML Agent Service Account** (`bqml-agent-sa@{project-id}.iam.gserviceaccount.com`)
  - For ML operations and AutoML model creation
  - Permissions: BigQuery admin, AI Platform user, data owner

- **Vertex AI Agent Service Account** (`vertex-agent-sa@{project-id}.iam.gserviceaccount.com`)
  - For Vertex AI operations and Agent Engine integration
  - Permissions: AI Platform admin, BigQuery viewer

### 📊 Infrastructure Resources
- **BigQuery Dataset**: `titanic_dataset` for ML training data
- **Secret Manager**: Secure storage for Gemini API key
- **Storage Bucket**: `adk-artifacts` for agent packages and artifacts
- **APIs Enabled**: AI Platform, Compute Engine, Secret Manager

### 🔒 Security Configuration
- **Least Privilege IAM**: Each service account has minimal required permissions
- **Service Account Impersonation**: ADK agent can impersonate specialized agents
- **Secret Access**: Secure Gemini API key access for AI functionality

## Post-Deployment Verification

### 1. Verify Service Accounts
```bash
# List all ADK service accounts
gcloud iam service-accounts list --filter="displayName:(*ADK* OR *BigQuery ML* OR *Vertex AI*)"

# Get service account emails from Terraform outputs
terraform output adk_agent_service_account_email
terraform output bqml_agent_service_account_email  
terraform output vertex_agent_service_account_email
```

### 2. Verify Infrastructure
```bash
# Check BigQuery dataset
bq ls --datasets --project_id={your-project-id}

# Verify Secret Manager
gcloud secrets list --filter="name:gemini-api-key"

# Check storage bucket
gsutil ls gs://{your-project-id}-adk-artifacts
```

### 3. Test Gemini API Access
```python
# test_gemini_access.py
import os
from google.cloud import secretmanager

def test_gemini_access():
    """Test access to Gemini API key from Secret Manager."""
    client = secretmanager.SecretManagerServiceClient()
      # Access the secret
    project_id = "{your-project-id}"
    secret_name = "gemini-api-key"
    name = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
    
    response = client.access_secret_version(request={"name": name})
    secret_value = response.payload.data.decode("UTF-8")
    
    print(f"✅ Successfully accessed Gemini API key: {secret_value[:10]}...")
    return secret_value

if __name__ == "__main__":
    test_gemini_access()
```

## Next Steps: ADK Agent Development

With infrastructure deployed, you can now proceed to **Phase 3: ADK Agent Development**:

1. **Load Titanic Dataset**: Populate the BigQuery dataset with training data
2. **Create ADK Agents**: Implement data science agents using the new service accounts
3. **Set Up Agent Orchestration**: Configure agent workflow and communication
4. **Deploy Agent Frontend**: Set up `adk web` interface for agent interaction

## Troubleshooting

### Common Issues

1. **"API key required" error**:
   - Ensure you've obtained your Gemini API key from Google AI Studio
   - Verify the key is correctly passed to the Terraform command

2. **Permission denied errors**:
   - Verify you're authenticated: `gcloud auth list`
   - Ensure your account has project owner/editor permissions

3. **Terraform backend errors**:
   - Run: `terraform init -backend-config="bucket={your-project-id}-terraform-state"`

4. **Secret Manager access issues**:
   - Verify the Secret Manager API is enabled
   - Check service account has `secretmanager.secretAccessor` role

### Support Resources
- **ADK Development Instructions**: `docs/ADK_DEVELOPMENT_PHASE_INSTRUCTIONS.md`
- **GitHub Secrets Setup**: `GITHUB_SECRETS_SETUP.md`
- **Terraform Documentation**: `docs/TERRAFORM_IAM_CONFLICT_RESOLVED.md`

---

## 🎯 Success Criteria

After successful deployment, you should have:
- ✅ 3 ADK service accounts created and configured
- ✅ BigQuery dataset ready for Titanic data
- ✅ Gemini API key securely stored in Secret Manager
- ✅ Storage bucket for ADK artifacts
- ✅ All required APIs enabled
- ✅ Proper IAM permissions configured

**You're now ready to begin ADK agent implementation!** 🚀
