# Tests Directory

This directory contains all testing and validation scripts for the Agentic Data Science infrastructure. These scripts help ensure proper deployment, functionality, and ongoing health of your GCP resources.

## 📁 Test Scripts Overview

```
tests/
├── README.md                      # This documentation
├── test_deployment.ps1            # Comprehensive deployment testing
├── validate_deployment.sh         # Infrastructure validation
├── test_cloud_function.ps1        # Detailed Cloud Function testing
├── test_cloud_function_quick.sh   # Quick Cloud Function testing
└── test_adk_infrastructure.py     # ADK infrastructure testing
```

## 🧪 Test Scripts

### `test_deployment.ps1` - **Comprehensive Deployment Testing**
Complete end-to-end testing of Terraform deployment and data loading.

**Usage:**
```powershell
.\test_deployment.ps1 -ProjectId "your-project-id" -Region "us-east1" -Environment "dev"
```

**Test Coverage:**
- Terraform initialization and validation
- Terraform plan generation
- Optional infrastructure deployment
- Data loading script execution
- End-to-end workflow validation

**Parameters:**
- `-ProjectId` - GCP Project ID (required)
- `-Region` - GCP region (default: us-east1)
- `-Environment` - Environment name (default: dev)

### `validate_deployment.sh` - **Infrastructure Validation**
Validates that all required GCP resources are properly deployed and configured.

**Usage:**
```bash
./validate_deployment.sh your-project-id
```

**Validation Checks:**
- ✅ BigQuery dataset and table existence
- ✅ Cloud Storage bucket configuration
- ✅ Cloud Function deployment status
- ✅ Secret Manager secrets
- ✅ Service account permissions
- ✅ IAM policy bindings
- ✅ API enablement status

**Output:** Comprehensive validation report with pass/fail status for each resource.

### `test_cloud_function.ps1` - **Detailed Cloud Function Testing**
Comprehensive testing suite for Cloud Function functionality and performance.

**Usage:**
```powershell
.\test_cloud_function.ps1 -ProjectId "your-project-id" -TestMode "full"
```

**Test Modes:**
- `full` - Complete testing including file upload, processing, and BigQuery validation
- `quick` - Basic function status and simple trigger test
- `logs-only` - Only fetch and analyze recent function logs
- `function-status` - Just check deployment status and configuration

**Test Coverage:**
- Function deployment verification
- File upload trigger testing
- Log monitoring and analysis
- BigQuery data validation
- Error scenario testing
- Performance metrics collection

### `test_cloud_function_quick.sh` - **Quick Cloud Function Testing**
Fast, lightweight test for basic Cloud Function functionality.

**Usage:**
```bash
./test_cloud_function_quick.sh your-project-id
```

**Quick Tests:**
- Function deployment status
- Basic trigger test with sample file
- Recent error checking
- Simple pass/fail validation

**Use Case:** Perfect for CI/CD pipelines or quick health checks.

### `test_adk_infrastructure.py` - **ADK Infrastructure Testing**
Python-based testing for Agent Development Kit infrastructure components.

**Usage:**
```python
python test_adk_infrastructure.py --project-id your-project-id --api-key your-gemini-api-key
```

**Test Coverage:**
- Direct Gemini API access validation
- Secret Manager API key retrieval
- BigQuery dataset accessibility
- Service account authentication
- ADK component integration testing

**Requirements:**
```bash
pip install google-cloud-secret-manager google-cloud-bigquery google-generativeai
```

## 🔄 Testing Workflows

### Quick Health Check
```bash
# Fast validation of core infrastructure
./validate_deployment.sh your-project-id
./test_cloud_function_quick.sh your-project-id
```

### Pre-Deployment Testing
```powershell
# Test Terraform configuration before applying
.\test_deployment.ps1 -ProjectId "your-project-id" -Environment "staging"
```

### Post-Deployment Validation
```bash
# Comprehensive validation after deployment
./validate_deployment.sh your-project-id
```

```powershell
# Detailed function testing
.\test_cloud_function.ps1 -ProjectId "your-project-id" -TestMode "full"
```

### ADK Development Testing
```python
# Test ADK components and API access
python test_adk_infrastructure.py --project-id your-project-id --api-key your-api-key
```

### Continuous Monitoring
```powershell
# Monitor function health over time
.\test_cloud_function.ps1 -ProjectId "your-project-id" -TestMode "logs-only"
```

## 📊 Test Reports

### Validation Report Format
```
🔍 Validating Agentic Data Science deployment for project: your-project-id

📊 BigQuery Resources:
  Checking dataset 'test_dataset'... ✅ EXISTS
  Checking table 'test_dataset.titanic'... ✅ EXISTS

🪣 Storage Resources:
  Checking bucket 'your-project-id-temp-bucket'... ✅ EXISTS
  Checking bucket 'your-project-id-adk-storage'... ✅ EXISTS

⚡ Cloud Functions:
  Checking function 'csv-to-bigquery-loader'... ✅ EXISTS

🔐 Secret Manager:
  Checking secret 'gemini-api-key'... ✅ EXISTS

👥 Service Accounts:
  Checking SA 'adk-service-account@your-project-id.iam.gserviceaccount.com'... ✅ EXISTS

🛡️ IAM Permissions:
  Checking BigQuery permissions... ✅ CONFIGURED
  Checking Storage permissions... ✅ CONFIGURED

🔌 APIs:
  Checking Cloud Functions API... ✅ ENABLED
  Checking BigQuery API... ✅ ENABLED

✅ All validation checks passed! Infrastructure is properly deployed.
```

### Function Test Report
```
🧪 Cloud Function Test Results

✅ Function Status: ACTIVE
✅ File Upload: SUCCESS
✅ Function Trigger: SUCCESS  
✅ Data Processing: SUCCESS
✅ BigQuery Loading: SUCCESS

📊 Performance Metrics:
  - Execution Time: 2.3s
  - Memory Usage: 128MB
  - Success Rate: 100%

🔍 Recent Activity:
  - Last execution: 2025-05-26 18:15:32 UTC
  - Status: SUCCESS
  - Duration: 2.1s
```

## 🚨 Troubleshooting Test Failures

### Common Test Failures

**Authentication Issues:**
```bash
# Re-authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login
gcloud config set project your-project-id
```

**Resource Not Found:**
```bash
# Verify infrastructure deployment
./validate_deployment.sh your-project-id
```

**Permission Denied:**
```bash
# Check service account permissions
gcloud projects get-iam-policy your-project-id
```

**Function Not Responding:**
```bash
# Check function logs
gcloud functions logs read csv-to-bigquery-loader --project=your-project-id
```

**API Not Enabled:**
```bash
# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable bigquery.googleapis.com
```

### Test Script Debugging

**PowerShell Scripts:**
```powershell
# Enable verbose output
$VerbosePreference = "Continue"
.\test_deployment.ps1 -ProjectId "your-project-id" -Verbose
```

**Bash Scripts:**
```bash
# Enable debug mode
bash -x ./validate_deployment.sh your-project-id
```

**Python Scripts:**
```python
# Add debug logging
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 📋 Test Checklist

### Before Running Tests
- [ ] Google Cloud SDK installed and authenticated
- [ ] Project ID configured: `gcloud config set project your-project-id`
- [ ] Required APIs enabled
- [ ] Proper IAM permissions assigned
- [ ] Terraform infrastructure deployed

### Comprehensive Testing Sequence
1. [ ] Run infrastructure validation: `./validate_deployment.sh`
2. [ ] Test basic function: `./test_cloud_function_quick.sh`
3. [ ] Comprehensive function test: `.\test_cloud_function.ps1 -TestMode full`
4. [ ] ADK components test: `python test_adk_infrastructure.py`
5. [ ] End-to-end deployment test: `.\test_deployment.ps1`

### Regular Health Checks
- [ ] Weekly: Quick function test
- [ ] Monthly: Full infrastructure validation
- [ ] Before releases: Complete test suite
- [ ] After changes: Targeted component tests

## 🔗 Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Run Infrastructure Tests
  run: |
    ./tests/validate_deployment.sh ${{ secrets.GCP_PROJECT_ID }}
    ./tests/test_cloud_function_quick.sh ${{ secrets.GCP_PROJECT_ID }}
```

### Local Development Testing
```powershell
# Quick pre-commit test
.\tests\test_cloud_function_quick.sh your-project-id

# Pre-push comprehensive test
.\tests\test_deployment.ps1 -ProjectId "your-project-id"
```

## 📚 Related Documentation

- **Main Scripts**: `../scripts/README.md`
- **Cloud Function Testing Guide**: `../docs/CLOUD_FUNCTION_TESTING_GUIDE.md`
- **Developer Onboarding**: `../docs/DEVELOPER_ONBOARDING_GUIDE.md`
- **Deployment Guide**: `../docs/ADK_DEPLOYMENT_GUIDE.md`

---

## 📈 Test Coverage Summary

**Infrastructure Components Tested:**
- ✅ BigQuery datasets and tables
- ✅ Cloud Storage buckets
- ✅ Cloud Functions deployment and execution
- ✅ Secret Manager secrets
- ✅ Service accounts and IAM permissions
- ✅ API enablement status
- ✅ ADK component integration
- ✅ End-to-end data pipeline

**Test Types:**
- **Unit Tests**: Individual component validation
- **Integration Tests**: Component interaction testing
- **End-to-End Tests**: Complete workflow validation
- **Performance Tests**: Function execution metrics
- **Health Checks**: Ongoing system monitoring

**Coverage: 100% of deployed infrastructure components**
