# Migration script for implementing IAM as Code
# This script helps migrate from manual IAM to Terraform-managed IAM

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "🔄 Migrating to IAM as Code for project: $ProjectId" -ForegroundColor Cyan
Write-Host ""

# Check if gcloud is authenticated
try {
    $currentProject = gcloud config get-value project 2>$null
    if ($currentProject -ne $ProjectId) {
        Write-Host "⚠️  Setting gcloud project to: $ProjectId" -ForegroundColor Yellow
        gcloud config set project $ProjectId
    }
} catch {
    Write-Host "❌ Please authenticate with gcloud first: gcloud auth login" -ForegroundColor Red
    exit 1
}

Write-Host "📋 IAM Migration Checklist:" -ForegroundColor Green
Write-Host ""

# 1. Update terraform.tfvars
Write-Host "1. ✅ Updating terraform.tfvars..." -ForegroundColor Blue
$tfvarsPath = "terraform\terraform.tfvars"
if (Test-Path $tfvarsPath) {
    Write-Host "   📝 Backing up existing terraform.tfvars" -ForegroundColor Gray
    Copy-Item $tfvarsPath "$tfvarsPath.backup"
}

$tfvarsContent = @"
# Terraform variable values for IAM as Code migration
# Generated on $(Get-Date)

project_id  = "$ProjectId"
region      = "$Region"
environment = "$Environment"
"@

Set-Content -Path $tfvarsPath -Value $tfvarsContent
Write-Host "   ✅ Created $tfvarsPath" -ForegroundColor Green

# 2. Check existing service accounts
Write-Host ""
Write-Host "2. 🔍 Checking existing service accounts..." -ForegroundColor Blue
$existingSAs = gcloud iam service-accounts list --format="value(email)" --filter="email:github-actions-terraform OR email:cloud-function-bigquery"

if ($existingSAs) {
    Write-Host "   ⚠️  Found existing service accounts that may conflict:" -ForegroundColor Yellow
    $existingSAs | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
    Write-Host "   💡 Terraform will import or recreate these as needed" -ForegroundColor Gray
} else {
    Write-Host "   ✅ No conflicting service accounts found" -ForegroundColor Green
}

# 3. Validate Terraform configuration
Write-Host ""
Write-Host "3. 🔧 Validating Terraform configuration..." -ForegroundColor Blue
Push-Location terraform
try {
    # Initialize without backend first to validate syntax
    terraform init -backend=false
    if ($LASTEXITCODE -eq 0) {
        terraform validate
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Terraform configuration is valid" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Terraform validation failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "   ❌ Terraform initialization failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

# 4. Check required APIs
Write-Host ""
Write-Host "4. 🌐 Checking required APIs..." -ForegroundColor Blue
$requiredAPIs = @(
    "bigquery.googleapis.com",
    "storage.googleapis.com", 
    "cloudfunctions.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com"
)

foreach ($api in $requiredAPIs) {
    $enabled = gcloud services list --enabled --filter="name:$api" --format="value(name)" 2>$null
    if ($enabled) {
        Write-Host "   ✅ $api" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  $api (will be enabled by Terraform)" -ForegroundColor Yellow
    }
}

# 5. Generate deployment plan
Write-Host ""
Write-Host "5. 📊 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Ensure GitHub Secrets are configured:" -ForegroundColor White
Write-Host "      - GCP_PROJECT_ID: $ProjectId" -ForegroundColor Gray
Write-Host "      - GCP_REGION: $Region" -ForegroundColor Gray
Write-Host "      - GCP_ENVIRONMENT: $Environment" -ForegroundColor Gray
Write-Host "      - GCP_SERVICE_ACCOUNT_KEY: (will be generated)" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Run Terraform locally to generate service account key:" -ForegroundColor White
Write-Host "      cd terraform" -ForegroundColor Gray
Write-Host "      terraform init -backend-config=`"bucket=$ProjectId-terraform-state`"" -ForegroundColor Gray
Write-Host "      terraform plan" -ForegroundColor Gray
Write-Host "      terraform apply" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Update GitHub Secret with generated key:" -ForegroundColor White
Write-Host "      Use content from: github-actions-key.json" -ForegroundColor Gray
Write-Host ""
Write-Host "   4. Push to GitHub to trigger automated deployment" -ForegroundColor White

Write-Host ""
Write-Host "🎯 IAM as Code migration preparation complete!" -ForegroundColor Green
Write-Host "   📚 See GITHUB_SECRETS_SETUP.md for detailed instructions" -ForegroundColor Gray
