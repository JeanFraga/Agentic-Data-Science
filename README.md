# Agentic Data Science

[![Terraform CI/CD](https://github.com/JeanFraga/agentic-data-science/actions/workflows/terraform.yml/badge.svg)](https://github.com/JeanFraga/agentic-data-science/actions/workflows/terraform.yml)

An automated, event-driven data science platform built on Google Cloud Platform (GCP) that demonstrates Infrastructure as Code (IaC) principles with Terraform, automated data ingestion via Cloud Functions, and BigQuery analytics using the classic Titanic dataset.

## 🏗️ Architecture

This repository implements a complete data pipeline with:

- **Infrastructure as Code**: Terraform manages all GCP resources
- **Event-Driven Processing**: Cloud Functions automatically trigger on data uploads
- **Automated CI/CD**: GitHub Actions for continuous deployment
- **Data Warehousing**: BigQuery for analytics and ML-ready datasets
- **State Management**: Remote Terraform state in Google Cloud Storage

## 🚀 Features

- ✅ **Automated Infrastructure Deployment** via Terraform
- ✅ **Event-Driven Data Loading** with Cloud Functions
- ✅ **BigQuery Dataset Management** with schema auto-detection
- ✅ **Remote State Management** with versioning
- ✅ **GitHub Actions CI/CD** pipeline
- ✅ **Service Account Security** with minimal required permissions
- ✅ **Comprehensive Validation** and testing scripts

## 📦 Infrastructure Components

### Core Resources
- **BigQuery Dataset**: `test_dataset` for analytics workloads
- **Cloud Storage Buckets**: 
  - Terraform state storage with versioning
  - Temporary data processing bucket
  - Cloud Function source code storage
- **Cloud Function**: `titanic-data-loader` for automated data ingestion
- **Service Account**: Dedicated SA with minimal required permissions

### Enabled APIs
- BigQuery API
- Cloud Storage API
- Cloud Functions API (Gen 2)
- Eventarc API
- Cloud Run API
- Pub/Sub API

## 📚 Documentation

For detailed implementation guides and reports, see our comprehensive documentation:

**📋 [Documentation Index](docs/INDEX.md)** - Complete navigation guide

### Quick Links
- 🎯 [Final Success Report](docs/FINAL_SUCCESS_REPORT.md) - Project completion summary
- 🔐 [IAM as Code Guide](docs/IAM_AS_CODE_GUIDE.md) - Security implementation
- 🧪 [Cloud Function Testing Guide](docs/CLOUD_FUNCTION_TESTING_GUIDE.md) - Testing procedures
- 🛡️ [Security Validation Report](docs/SECURITY_VALIDATION_REPORT.md) - Security compliance

## 🛠️ Quick Start

### Prerequisites
- Google Cloud Project with billing enabled
- GitHub repository with Actions enabled
- Git and PowerShell (for local setup)
- Terraform installed locally (optional, for testing)

### 1. Initial Setup (IAM as Code)

```powershell
# Clone and setup the repository
git clone <your-repo-url>
cd "Agentic Data Science"

# Run the IAM migration script
.\scripts\migrate_to_iam_as_code.ps1 -ProjectId "your-gcp-project-id" -Region "us-central1" -Environment "dev"
```

### 2. Generate Service Account (One-time)

```powershell
# Deploy locally to generate service account key
cd terraform
terraform init -backend-config="bucket=your-project-id-terraform-state"
terraform apply

# The github-actions-key.json file will be created automatically
```

### 3. Configure GitHub Secrets

Follow the detailed guide in [`GITHUB_SECRETS_SETUP.md`](GITHUB_SECRETS_SETUP.md) to configure:
- `GCP_PROJECT_ID`
- `GCP_REGION` 
- `GCP_ENVIRONMENT`
- `GCP_SERVICE_ACCOUNT_KEY` (use content from generated `github-actions-key.json`)

### 4. Deploy via CI/CD

```powershell
# Commit configuration and push to trigger automated deployment
git add .
git commit -m "Configure deployment for project"
git push origin main
```

### 4. Validate Deployment

```powershell
# Run validation script
.\scripts\validate_deployment.sh your-project-id

# Check BigQuery data
# The pipeline automatically loads the Titanic dataset
```
- gcloud CLI configured (optional, for testing)

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/agentic-data-science.git
cd agentic-data-science
```

### 2. Configure GitHub Secrets
Follow the detailed instructions in [`GITHUB_SECRETS_SETUP.md`](GITHUB_SECRETS_SETUP.md) to configure:
- `GCP_PROJECT_ID`
- `GCP_REGION` 
- `GCP_ENVIRONMENT`
- `GCP_SERVICE_ACCOUNT_KEY`

### 3. Deploy Infrastructure
Push to the `main` branch to trigger automatic deployment:
```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

The GitHub Actions workflow will:
1. Authenticate to GCP
2. Initialize and validate Terraform
3. Deploy infrastructure
4. Load Titanic dataset to BigQuery

### 4. Verify Deployment
Use the validation script to check all resources:
```bash
# Via WSL/Linux
chmod +x scripts/validate_deployment.sh
./scripts/validate_deployment.sh YOUR_PROJECT_ID

# Via PowerShell (local testing)
.\scripts\test_deployment.ps1 -ProjectId "YOUR_PROJECT_ID"
```

## 🔄 How It Works

### Data Flow
1. **Trigger**: Upload `titanic.csv` to the temp bucket
2. **Processing**: Cloud Function automatically detects the file
3. **Transformation**: CSV data is cleaned and processed
4. **Loading**: Data is loaded into BigQuery with schema auto-detection
5. **Analytics**: Data is ready for SQL queries and ML workloads

### Cloud Function Workflow
```python
# Automatic trigger on CSV upload
Cloud Storage Event → Cloud Function → BigQuery Load
```

The function handles:
- Event filtering (only processes `titanic.csv`)
- Data validation and cleaning
- Schema auto-detection
- Error handling and logging

## 📊 Data Analysis

Once deployed, you can analyze the Titanic dataset:

```sql
-- Basic statistics
SELECT 
    COUNT(*) as total_passengers,
    AVG(Age) as avg_age,
    SUM(Survived) as survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 2) as survival_rate_percent
FROM `YOUR_PROJECT_ID.test_dataset.titanic`
WHERE Age IS NOT NULL;

-- Survival by passenger class
SELECT 
    Pclass,
    COUNT(*) as total,
    SUM(Survived) as survived,
    ROUND(AVG(Survived) * 100, 2) as survival_rate
FROM `YOUR_PROJECT_ID.test_dataset.titanic`
GROUP BY Pclass
ORDER BY Pclass;
```

## 🧪 Testing

### Local Testing
```powershell
# Test Terraform configuration
.\scripts\test_deployment.ps1 -ProjectId "your-project-id" -Region "us-central1"
```

### End-to-End Testing
```bash
# Upload test data to trigger the pipeline
gsutil cp titanic.csv gs://your-project-id-temp-bucket/

# Monitor Cloud Function logs
gcloud functions logs read titanic-data-loader --region=us-central1
```

### Validation
```bash
# Comprehensive infrastructure validation
./scripts/validate_deployment.sh your-project-id
```

## 📁 Project Structure

```
├── README.md                          # This file
├── GITHUB_SECRETS_SETUP.md           # GitHub configuration guide
├── .github/workflows/
│   └── terraform.yml                 # CI/CD pipeline
├── terraform/
│   ├── main.tf                       # Core infrastructure
│   ├── variables.tf                  # Variable definitions
│   ├── terraform.tfvars              # Variable values
│   ├── backend.tf                    # Remote state configuration
│   ├── cloud_function.tf             # Cloud Function resources
│   └── function/
│       ├── main.py                   # Cloud Function code
│       └── requirements.txt          # Python dependencies
└── scripts/
    ├── check_and_load_titanic_data.sh # Data loading script
    ├── validate_deployment.sh         # Infrastructure validation
    └── test_deployment.ps1            # Local testing (PowerShell)
```

## 🔐 Security

- **Service Account**: Dedicated SA with minimal required permissions
- **IAM Roles**: 
  - `roles/bigquery.dataEditor` for BigQuery operations
  - `roles/storage.objectViewer` for Cloud Storage access
- **Secure Secrets**: GitHub Secrets for sensitive credentials
- **Remote State**: Terraform state stored securely in GCS

## 📈 Monitoring & Observability

- **Cloud Function Logs**: Detailed execution logs in Cloud Logging
- **BigQuery Job History**: Track all data loading operations
- **GitHub Actions**: CI/CD pipeline execution history
- **Terraform State**: Version-controlled infrastructure changes

## 🔧 Customization

### Adding New Datasets
1. Update the Cloud Function to handle additional CSV files
2. Modify the event filter in `cloud_function.tf`
3. Add new BigQuery tables in `main.tf`

### Scaling for Production
- Increase Cloud Function memory and timeout
- Add error handling and retry logic
- Implement data validation schemas
- Add monitoring and alerting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally using the provided scripts
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙋‍♂️ Support

- **Issues**: GitHub Issues for bug reports and feature requests
- **Documentation**: Check the `GITHUB_SECRETS_SETUP.md` for detailed configuration
- **Testing**: Use the validation scripts to troubleshoot deployments

---

**Built with ❤️ using Terraform, Google Cloud Platform, and GitHub Actions**
