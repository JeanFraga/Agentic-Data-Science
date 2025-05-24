# GitHub Secrets Configuration Guide

This document provides step-by-step instructions for setting up the required GitHub Secrets for the Agentic Data Science CI/CD pipeline.

## Required Secrets

The following secrets need to be configured in your GitHub repository:

### 1. GCP_PROJECT_ID
- **Value**: Your Google Cloud Project ID
- **Example**: `my-data-science-project-12345`

### 2. GCP_REGION
- **Value**: The GCP region where resources will be deployed
- **Example**: `us-central1`

### 3. GCP_ENVIRONMENT
- **Value**: The environment name for resource labeling
- **Example**: `dev`, `staging`, or `prod`

### 4. GCP_SERVICE_ACCOUNT_KEY
- **Value**: JSON key for a GCP service account with appropriate permissions
- **Required Roles**:
  - `BigQuery Admin`
  - `Storage Admin`
  - `Cloud Functions Admin`
  - `Service Account Admin`
  - `Project IAM Admin`
  - `Service Usage Admin`

## Setting Up GitHub Secrets

1. Navigate to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the name and value as specified above

## Creating the GCP Service Account

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **IAM & Admin** → **Service Accounts**
3. Click **Create Service Account**
4. Fill in the details:
   - **Service account name**: `github-actions-terraform`
   - **Description**: `Service account for GitHub Actions Terraform deployments`
5. Click **Create and Continue**
6. Assign the following roles:
   - `BigQuery Admin`
   - `Storage Admin`
   - `Cloud Functions Admin`
   - `Service Account Admin`
   - `Project IAM Admin`
   - `Service Usage Admin`
7. Click **Continue** and then **Done**
8. Find your new service account in the list and click on it
9. Go to the **Keys** tab
10. Click **Add Key** → **Create new key**
11. Choose **JSON** format and click **Create**
12. Download the JSON file and use its contents as the value for `GCP_SERVICE_ACCOUNT_KEY`

## Testing the Setup

Once all secrets are configured:

1. Push changes to the `main` branch
2. Check the **Actions** tab in your GitHub repository
3. Monitor the workflow execution
4. Verify resources are created in your GCP project

## Local Testing (Optional)

Before pushing to GitHub, you can test locally:

```powershell
# Set environment variables
$env:TF_VAR_project_id = "your-project-id"
$env:TF_VAR_region = "us-central1"
$env:TF_VAR_environment = "dev"

# Run the test script
.\scripts\test_deployment.ps1 -ProjectId "your-project-id"
```

## Troubleshooting

### Common Issues:

1. **Permission Denied**: Ensure the service account has all required roles
2. **API Not Enabled**: The Terraform configuration automatically enables required APIs
3. **Quota Exceeded**: Check your GCP quotas for Cloud Functions and BigQuery
4. **Authentication Failed**: Verify the service account JSON is correctly formatted in the secret

### Useful Commands:

```bash
# Check Terraform state
terraform state list

# View Cloud Function logs
gcloud functions logs read titanic-data-loader --region=us-central1

# Query BigQuery table
bq query --use_legacy_sql=false "SELECT COUNT(*) FROM \`PROJECT_ID.test_dataset.titanic\`"
```

## Next Steps

After successful deployment:

1. Upload `titanic.csv` to the temp bucket to test the Cloud Function
2. Verify data appears in BigQuery
3. Set up monitoring and alerting as needed
4. Consider adding more sophisticated data processing workflows
