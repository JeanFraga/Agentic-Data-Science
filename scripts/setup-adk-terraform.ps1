# ADK Terraform Setup Script
# This script helps set up the ADK infrastructure using Terraform

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [string]$GeminiApiKey,
    
    [string]$Region = "us-east1",
    [string]$Environment = "dev",
    [switch]$GenerateKeys,
    [switch]$PlanOnly,
    [switch]$Help
)

function Show-Help {
    Write-Host "🚀 ADK Terraform Setup Script" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script deploys Google Agent Development Kit (ADK) infrastructure including:" -ForegroundColor White
    Write-Host "  • ADK Service Accounts with proper IAM permissions" -ForegroundColor Gray
    Write-Host "  • BigQuery dataset for Titanic ML training" -ForegroundColor Gray
    Write-Host "  • Secret Manager for secure Gemini API key storage" -ForegroundColor Gray
    Write-Host "  • Storage bucket for ADK artifacts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\setup-adk-terraform.ps1 [-ProjectId <PROJECT>] [-GeminiApiKey <API_KEY>] [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -ProjectId      GCP Project ID (default: agentic-data-science-460701)" -ForegroundColor White
    Write-Host "  -GeminiApiKey   Gemini API key from Google AI Studio (get free at: https://aistudio.google.com/app/apikey)" -ForegroundColor White
    Write-Host "  -Region         GCP region (default: us-east1)" -ForegroundColor White
    Write-Host "  -Environment    Environment name (default: dev)" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -PlanOnly       Show Terraform plan without applying changes" -ForegroundColor White
    Write-Host "  -GenerateKeys   Generate service account keys for local development" -ForegroundColor White
    Write-Host "  -Help           Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Deploy with your API key" -ForegroundColor Gray
    Write-Host "  .\setup-adk-terraform.ps1 -GeminiApiKey 'YOUR_API_KEY_HERE'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Plan only (review changes)" -ForegroundColor Gray
    Write-Host "  .\setup-adk-terraform.ps1 -GeminiApiKey 'YOUR_API_KEY_HERE' -PlanOnly" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Include service account key generation" -ForegroundColor Gray
    Write-Host "  .\setup-adk-terraform.ps1 -GeminiApiKey 'YOUR_API_KEY_HERE' -GenerateKeys" -ForegroundColor White
    Write-Host ""
    Write-Host "GET GEMINI API KEY:" -ForegroundColor Green
    Write-Host "  1. Visit: https://aistudio.google.com/app/apikey" -ForegroundColor White
    Write-Host "  2. Sign in with your Google account" -ForegroundColor White
    Write-Host "  3. Click 'Get API Key' button" -ForegroundColor White
    Write-Host "  4. Copy the generated key (FREE - 60 requests/minute)" -ForegroundColor White
    Write-Host ""
    exit 0
}

if ($Help) {
    Show-Help
}

# Set defaults if not provided
if (-not $ProjectId) {
    $ProjectId = "agentic-data-science-460701"
    Write-Host "Using default project: $ProjectId" -ForegroundColor Yellow
}

if (-not $GeminiApiKey) {
    Write-Host ""
    Write-Host "❌ Gemini API key is required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Get your FREE Gemini API key:" -ForegroundColor Yellow
    Write-Host "  1. Visit: https://aistudio.google.com/app/apikey" -ForegroundColor White
    Write-Host "  2. Sign in with your Google account" -ForegroundColor White
    Write-Host "  3. Click 'Get API Key' button" -ForegroundColor White
    Write-Host "  4. Copy the generated key" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run: .\setup-adk-terraform.ps1 -GeminiApiKey 'YOUR_API_KEY_HERE'" -ForegroundColor Green
    Write-Host ""
    Write-Host "Use -Help for more options" -ForegroundColor Gray
    exit 1
}

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 ADK Terraform Setup Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
if ($PlanOnly) { Write-Host "Mode: PLAN ONLY" -ForegroundColor Magenta }
if ($GenerateKeys) { Write-Host "Generate Keys: YES" -ForegroundColor Magenta }

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check if gcloud is installed
try {
    $gcloudVersion = gcloud version --format="value(Google Cloud SDK)" 2>$null
    Write-Host "✅ Google Cloud SDK: $gcloudVersion" -ForegroundColor Green
} catch {
    Write-Error "❌ Google Cloud SDK not found. Please install: https://cloud.google.com/sdk/docs/install"
    exit 1
}

# Check if terraform is installed
try {
    $terraformVersion = terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version
    Write-Host "✅ Terraform: $terraformVersion" -ForegroundColor Green
} catch {
    Write-Error "❌ Terraform not found. Please install: https://www.terraform.io/downloads"
    exit 1
}

# Set gcloud project
Write-Host "📝 Setting up Google Cloud project..." -ForegroundColor Yellow
gcloud config set project $ProjectId

# Verify project access
try {
    $currentProject = gcloud config get-value project
    if ($currentProject -ne $ProjectId) {
        throw "Project mismatch"
    }
    Write-Host "✅ Project set to: $currentProject" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to set or verify project. Please check your permissions."
    exit 1
}

# Navigate to terraform directory
$TerraformDir = Join-Path $PSScriptRoot ".." "terraform"
if (!(Test-Path $TerraformDir)) {
    Write-Error "❌ Terraform directory not found: $TerraformDir"
    exit 1
}

Set-Location $TerraformDir
Write-Host "📁 Working directory: $TerraformDir" -ForegroundColor Green

# Create terraform.tfvars if it doesn't exist
$TfVarsFile = "terraform.tfvars"
if (!(Test-Path $TfVarsFile)) {
    Write-Host "📝 Creating terraform.tfvars..." -ForegroundColor Yellow
    
    $tfVarsContent = @"
# ADK Terraform Variables
# Auto-generated by setup-adk-terraform.ps1

project_id = "$ProjectId"
region = "$Region"
environment = "$Environment"
gemini_api_key = "$GeminiApiKey"

# GitHub Configuration (update if needed)
github_owner = "JeanFraga"
github_repo_name = "agentic-data-science"
deployment_branch = "main"

# BigQuery Configuration
dataset_id = "titanic_dataset"
bq_location = "US"
"@
    
    $tfVarsContent | Out-File -FilePath $TfVarsFile -Encoding UTF8
    Write-Host "✅ Created terraform.tfvars" -ForegroundColor Green
} else {
    Write-Host "ℹ️ terraform.tfvars already exists" -ForegroundColor Blue
}

# Initialize Terraform
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Terraform init failed"
    exit 1
}

Write-Host "✅ Terraform initialized" -ForegroundColor Green

# Plan deployment
Write-Host "📋 Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Terraform plan failed"
    exit 1
}

Write-Host "✅ Terraform plan completed" -ForegroundColor Green

# Apply if not plan-only
if (!$PlanOnly) {
    Write-Host "🚀 Applying Terraform configuration..." -ForegroundColor Yellow
    Write-Host "⚠️ This will create real resources in GCP" -ForegroundColor Red
    
    $confirmation = Read-Host "Continue with apply? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        terraform apply tfplan
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Terraform apply failed"
            exit 1
        }
        
        Write-Host "✅ Terraform apply completed" -ForegroundColor Green
        
        # Generate service account keys if requested
        if ($GenerateKeys) {
            Write-Host "🔑 Generating service account keys..." -ForegroundColor Yellow
            
            $serviceAccounts = @(
                @{Name="adk-agent"; File="adk-agent-key.json"},
                @{Name="bqml-agent"; File="bqml-agent-key.json"},
                @{Name="vertex-agent"; File="vertex-agent-key.json"}
            )
            
            foreach ($sa in $serviceAccounts) {
                $saEmail = "$($sa.Name)-sa@$ProjectId.iam.gserviceaccount.com"
                $keyFile = $sa.File
                
                try {
                    gcloud iam service-accounts keys create $keyFile --iam-account=$saEmail
                    Write-Host "✅ Generated key for $saEmail -> $keyFile" -ForegroundColor Green
                } catch {
                    Write-Warning "⚠️ Failed to generate key for $saEmail"
                }
            }
            
            Write-Host "🔒 Remember to keep these keys secure and never commit them to git!" -ForegroundColor Red
        }
        
        # Display outputs
        Write-Host "📊 Terraform outputs:" -ForegroundColor Yellow
        terraform output
        
        Write-Host "`n🎉 ADK infrastructure setup complete!" -ForegroundColor Green
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Load Titanic dataset into BigQuery" -ForegroundColor White
        Write-Host "2. Set up ADK development environment" -ForegroundColor White
        Write-Host "3. Test agents with 'adk web'" -ForegroundColor White
        
    } else {
        Write-Host "❌ Apply cancelled by user" -ForegroundColor Yellow
    }
} else {
    Write-Host "📋 Plan-only mode completed. Review the plan and run without -PlanOnly to apply." -ForegroundColor Blue
}

Write-Host "`n✨ Setup script completed!" -ForegroundColor Cyan
