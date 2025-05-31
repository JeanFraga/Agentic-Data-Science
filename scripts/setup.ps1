# Setup script for Agentic Data Science deployment
# This script helps configure the initial setup

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "🚀 Setting up Agentic Data Science deployment..." -ForegroundColor Green
Write-Host "Project ID: $ProjectId"
Write-Host "Region: $Region"
Write-Host "Environment: $Environment"
Write-Host ""

# Check if terraform.tfvars exists
$tfvarsPath = "terraform\terraform.tfvars"
if (Test-Path $tfvarsPath) {
    Write-Host "⚠️  terraform.tfvars already exists. Backing up..." -ForegroundColor Yellow
    Copy-Item $tfvarsPath "$tfvarsPath.backup"
}

# Create terraform.tfvars
Write-Host "📝 Creating terraform.tfvars..." -ForegroundColor Blue
$tfvarsContent = @"
# Terraform variable values for Agentic Data Science
# Generated on $(Get-Date)

project_id  = "$ProjectId"
region      = "$Region"
environment = "$Environment"
"@

Set-Content -Path $tfvarsPath -Value $tfvarsContent

Write-Host "✅ Created $tfvarsPath" -ForegroundColor Green

# Check git status
Write-Host ""
Write-Host "📊 Current git status:" -ForegroundColor Blue
git status --porcelain

Write-Host ""
Write-Host "🔧 Next steps:" -ForegroundColor Cyan
Write-Host "1. Configure GitHub Secrets (see GITHUB_SECRETS_SETUP.md)"
Write-Host "2. Test locally: .\scripts\test_deployment.ps1 -ProjectId $ProjectId"
Write-Host "3. Commit and push: git add . && git commit -m 'Configure deployment' && git push"
Write-Host ""
Write-Host "📚 Documentation:"
Write-Host "- README.md - Project overview"
Write-Host "- GITHUB_SECRETS_SETUP.md - Secrets configuration"
Write-Host "- DEPLOYMENT_STATUS.md - Current status and next steps"
Write-Host ""
Write-Host "🎯 Setup complete! Ready for deployment." -ForegroundColor Green
