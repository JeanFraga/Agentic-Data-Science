# GitHub Repository Connection Setup for Cloud Functions
# This script helps connect your GitHub repository to Google Cloud Source Repositories

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [string]$GitHubOwner = "JeanFraga",
    [string]$RepoName = "agentic-data-science",
    [string]$Region = "us-east1"
)

Write-Host "🔗 Setting up GitHub Repository Connection for Cloud Functions" -ForegroundColor Cyan
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
Write-Host "GitHub Repo: $GitHubOwner/$RepoName" -ForegroundColor Yellow
Write-Host ""

# Check if gcloud is authenticated
Write-Host "🔐 Checking Google Cloud authentication..." -ForegroundColor Yellow
$authCheck = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $authCheck) {
    Write-Host "❌ Not authenticated with Google Cloud. Please run:" -ForegroundColor Red
    Write-Host "   gcloud auth login" -ForegroundColor White
    Write-Host "   gcloud auth application-default login" -ForegroundColor White
    exit 1
}
Write-Host "✅ Authenticated as: $authCheck" -ForegroundColor Green

# Set the project
Write-Host "🎯 Setting Google Cloud project..." -ForegroundColor Yellow
gcloud config set project $ProjectId
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set project. Please check the project ID." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Project set to: $ProjectId" -ForegroundColor Green

# Enable required APIs
Write-Host "🔧 Enabling required APIs..." -ForegroundColor Yellow
$apis = @(
    "sourcerepo.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "  Enabling $api..." -ForegroundColor Cyan
    gcloud services enable $api --project=$ProjectId
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to enable $api" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ All APIs enabled successfully" -ForegroundColor Green

# Create the source repository (this will be done by Terraform)
Write-Host "📂 Note: The Cloud Source Repository will be created by Terraform" -ForegroundColor Yellow
Write-Host "   Repository name: github_${GitHubOwner}_${RepoName}" -ForegroundColor Cyan

# Provide instructions for connecting GitHub
Write-Host ""
Write-Host "🔗 GitHub Repository Connection Instructions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. After running 'terraform apply', you'll need to connect your GitHub repo:" -ForegroundColor White
Write-Host "   - Go to Google Cloud Console > Source Repositories" -ForegroundColor Gray
Write-Host "   - Find the repository: github_${GitHubOwner}_${RepoName}" -ForegroundColor Gray
Write-Host "   - Click 'Connect to GitHub' and follow the setup wizard" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Alternative: Use gcloud command after Terraform creates the repo:" -ForegroundColor White
Write-Host "   gcloud source repos create github_${GitHubOwner}_${RepoName} --project=$ProjectId" -ForegroundColor Gray
Write-Host ""
Write-Host "3. The Cloud Function will then deploy directly from your GitHub repository!" -ForegroundColor White
Write-Host ""

# Show next steps
Write-Host "🚀 Next Steps:" -ForegroundColor Green
Write-Host "1. Run Terraform to create the infrastructure:" -ForegroundColor White
Write-Host "   cd terraform" -ForegroundColor Gray
Write-Host "   terraform init -backend-config=\""bucket=$ProjectId-terraform-state\""" -ForegroundColor Gray
Write-Host "   terraform plan" -ForegroundColor Gray
Write-Host "   terraform apply" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Connect your GitHub repository to the created Cloud Source Repository" -ForegroundColor White
Write-Host ""
Write-Host "3. Push changes to GitHub main branch to trigger automatic function deployment!" -ForegroundColor White
Write-Host ""
Write-Host "✅ Setup preparation complete!" -ForegroundColor Green
