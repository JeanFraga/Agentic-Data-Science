# Scripts Directory

This directory contains essential scripts for deploying, managing, and maintaining the Agentic Data Science infrastructure. All scripts have been organized and cleaned up for optimal usability.

## 📁 Directory Structure

```
scripts/                          # Core infrastructure scripts
├── README.md                     # This documentation
├── setup-adk-terraform.ps1       # Primary ADK deployment script
├── setup.ps1                     # Basic project setup
├── check_and_load_titanic_data.ps1 # Data loading utility
├── terraform-init-local.ps1      # Terraform initialization helper
├── terraform-plan-manager.ps1    # Advanced Terraform plan management
├── migrate_to_iam_as_code.ps1     # IAM migration helper
├── setup-github-deployment.ps1   # GitHub integration setup
├── handle-secret-import.ps1       # Secret Manager helper
├── monitor_cloud_function.ps1     # Cloud Function monitoring
└── diagnose_cloud_function.sh     # Cloud Function diagnostics

tests/                            # Testing and validation scripts
├── test_deployment.ps1           # Comprehensive deployment testing
├── validate_deployment.sh        # Infrastructure validation
├── test_cloud_function.ps1       # Detailed Cloud Function testing
├── test_cloud_function_quick.sh  # Quick Cloud Function testing
└── test_adk_infrastructure.py    # ADK infrastructure testing
```

## 🚀 Core Scripts

### Primary Deployment Scripts

#### `setup-adk-terraform.ps1` - **Main ADK Deployment Script**
Primary script for deploying the Google Agent Development Kit (ADK) infrastructure.

**Usage:**
```powershell
.\setup-adk-terraform.ps1 -GeminiApiKey "YOUR_API_KEY_HERE"
```

**Features:**
- Deploys ADK Service Accounts with proper IAM permissions
- Creates BigQuery dataset for Titanic ML training
- Sets up Secret Manager for secure Gemini API key storage
- Creates storage bucket for ADK artifacts
- Supports plan-only mode and key generation options

**Parameters:**
- `-ProjectId` - GCP Project ID (optional, reads from terraform.tfvars)
- `-GeminiApiKey` - Gemini API key from Google AI Studio (required)
- `-Region` - GCP region (default: us-east1)
- `-Environment` - Environment name (default: dev)
- `-PlanOnly` - Show Terraform plan without applying changes
- `-GenerateKeys` - Generate service account keys for local development

#### `setup.ps1` - **Basic Project Setup**
Creates initial project configuration and terraform.tfvars file.

**Usage:**
```powershell
.\setup.ps1 -ProjectId "your-project-id"
```

**Parameters:**
- `-ProjectId` - GCP Project ID (required)
- `-Region` - GCP region (default: us-east-1)
- `-Environment` - Environment name (default: dev)

### Data Management Scripts

#### `check_and_load_titanic_data.ps1` - **Data Loading Utility**
Ensures BigQuery dataset exists and loads Titanic data for ML training.

**Usage:**
```powershell
.\check_and_load_titanic_data.ps1 -ProjectId "your-project-id"
```

**Features:**
- Checks for existing BigQuery dataset and table
- Downloads Titanic dataset if needed
- Uploads data to Cloud Storage bucket
- Triggers Cloud Function for automatic BigQuery loading

### Terraform Management Scripts

#### `terraform-init-local.ps1` - **Terraform Initialization**
Simple helper for initializing Terraform with remote state backend.

**Usage:**
```powershell
cd terraform
..\scripts\terraform-init-local.ps1
```

#### `terraform-plan-manager.ps1` - **Advanced Plan Management**
Advanced Terraform plan management with GCS storage for team collaboration.

**Usage:**
```powershell
.\terraform-plan-manager.ps1 -Action plan -Environment main
.\terraform-plan-manager.ps1 -Action apply -PlanName "my-plan"
.\terraform-plan-manager.ps1 -Action list
.\terraform-plan-manager.ps1 -Action cleanup
```

**Features:**
- Store and retrieve Terraform plans in GCS
- List available plans
- Clean up old plans
- Environment-specific plan management

### Cloud Function Management Scripts

#### `monitor_cloud_function.ps1` - **Function Monitoring**
Real-time monitoring of Cloud Function health and performance.

**Usage:**
```powershell
.\monitor_cloud_function.ps1 -ProjectId "your-project-id" -MonitorDuration 10
```

**Features:**
- Real-time log streaming
- Function metrics and performance tracking
- Error rate monitoring
- Resource utilization tracking

#### `diagnose_cloud_function.sh` - **Function Diagnostics**
Comprehensive diagnostic tool for troubleshooting Cloud Function issues.

**Usage:**
```bash
./diagnose_cloud_function.sh your-project-id
```

**Features:**
- Function deployment status check
- Recent error analysis
- Performance metrics
- Configuration validation
- Detailed diagnostic report

### Integration & Migration Scripts

#### `setup-github-deployment.ps1` - **GitHub Integration**
Sets up GitHub repository connection for Cloud Functions deployment.

**Usage:**
```powershell
.\setup-github-deployment.ps1 -ProjectId "your-project-id"
```

**Features:**
- Enables required APIs
- Creates Cloud Source Repository connection
- Sets up Cloud Build triggers
- Configures GitHub webhook integration

#### `migrate_to_iam_as_code.ps1` - **IAM Migration**
Helper script for migrating from manual IAM to Terraform-managed IAM.

**Usage:**
```powershell
.\migrate_to_iam_as_code.ps1 -ProjectId "your-project-id"
```

**Features:**
- IAM migration checklist
- Current permissions audit
- Terraform IAM resource generation guidance
- Migration validation steps

#### `handle-secret-import.ps1` - **Secret Management**
Handles Secret Manager resource import for local development.

**Usage:**
```powershell
.\handle-secret-import.ps1 -ProjectId "your-project-id"
```

**Features:**
- Checks for existing secrets
- Imports existing secrets into Terraform state
- Handles import conflicts gracefully

## 🧪 Testing Scripts (../tests/)

All testing and validation scripts have been moved to the `tests/` directory for better organization:

- **`test_deployment.ps1`** - Comprehensive deployment testing
- **`validate_deployment.sh`** - Infrastructure validation
- **`test_cloud_function.ps1`** - Detailed Cloud Function testing
- **`test_cloud_function_quick.sh`** - Quick Cloud Function testing  
- **`test_adk_infrastructure.py`** - ADK infrastructure testing

See `tests/README.md` for detailed testing documentation.

## 📋 Prerequisites

### Required Tools
- **Google Cloud SDK (gcloud)** - For GCP authentication and management
- **Terraform** - For infrastructure as code deployment
- **PowerShell Core** - For cross-platform PowerShell script execution
- **Python 3.8+** - For Python-based testing scripts

### Authentication
Before running any scripts, ensure you're authenticated with Google Cloud:

```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project your-project-id
```

### Required APIs
The following Google Cloud APIs must be enabled:
- Cloud Functions API
- Cloud Build API
- Secret Manager API
- BigQuery API
- Cloud Storage API
- Source Repository API (for GitHub integration)

## 🔄 Common Workflows

### Initial Project Setup
1. Run basic setup: `.\setup.ps1 -ProjectId "your-project-id"`
2. Deploy ADK infrastructure: `.\setup-adk-terraform.ps1 -GeminiApiKey "your-api-key"`
3. Load test data: `.\check_and_load_titanic_data.ps1 -ProjectId "your-project-id"`
4. Run validation tests: `cd ..\tests && .\validate_deployment.sh your-project-id`

### Development Workflow
1. Initialize Terraform: `.\terraform-init-local.ps1`
2. Plan changes: `.\terraform-plan-manager.ps1 -Action plan`
3. Apply changes: `.\terraform-plan-manager.ps1 -Action apply`
4. Test deployment: `cd ..\tests && .\test_deployment.ps1 -ProjectId "your-project-id"`

### Monitoring & Troubleshooting
1. Monitor functions: `.\monitor_cloud_function.ps1 -ProjectId "your-project-id"`
2. Diagnose issues: `.\diagnose_cloud_function.sh your-project-id`
3. Quick function test: `cd ..\tests && .\test_cloud_function_quick.sh your-project-id`

## 🔐 Security Notes

- All scripts use placeholder values like `{project-id}` in documentation
- API keys should be provided as parameters, not hardcoded
- Scripts validate authentication before executing operations
- Sensitive operations require explicit confirmation prompts

## 📚 Additional Resources

- **Main Documentation**: `../docs/INDEX.md`
- **Developer Guide**: `../docs/DEVELOPER_ONBOARDING_GUIDE.md`
- **Deployment Guide**: `../docs/ADK_DEPLOYMENT_GUIDE.md`
- **Testing Guide**: `../docs/CLOUD_FUNCTION_TESTING_GUIDE.md`

## 🆘 Troubleshooting

### Common Issues

**Authentication Errors:**
```powershell
gcloud auth login
gcloud auth application-default login
```

**Terraform State Issues:**
```powershell
cd terraform
terraform init -reconfigure
```

**Permission Denied:**
- Ensure your account has Project Editor or custom IAM roles
- Check that required APIs are enabled
- Verify service account permissions

**Script Execution Policy (Windows):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📄 Script Inventory (Post-Cleanup)

**Removed Scripts:**
- `check_and_load_titanic_data.sh` - Redundant bash version (kept PowerShell version)

**Relocated Scripts:**
- All test scripts moved to `../tests/` directory for better organization

**Remaining Scripts: 10 essential infrastructure management scripts**
- **Reduced from 16 to 10 scripts** (37.5% reduction)
- **5 test scripts** organized in dedicated test directory
- **Zero redundancy** - each script serves a unique purpose

This cleanup resulted in a **37.5% reduction in script count** while improving organization and maintaining full functionality.
