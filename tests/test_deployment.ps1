# PowerShell script to test the Terraform deployment locally
# Usage: .\test_deployment.ps1 -ProjectId "your-gcp-project-id" -Region "us-central1" -Environment "dev"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east1",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "Testing Agentic Data Science Terraform Deployment" -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Set environment variables for Terraform
$env:TF_VAR_project_id = $ProjectId
$env:TF_VAR_region = $Region
$env:TF_VAR_environment = $Environment

try {
    # Change to terraform directory
    Push-Location -Path "..\terraform"
    
    Write-Host "`nStep 1: Terraform Init" -ForegroundColor Cyan
    terraform init
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
    
    Write-Host "`nStep 2: Terraform Validate" -ForegroundColor Cyan
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validate failed" }
    
    Write-Host "`nStep 3: Terraform Plan" -ForegroundColor Cyan
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }
    
    Write-Host "`nStep 4: Terraform Apply (with approval)" -ForegroundColor Cyan
    $apply = Read-Host "Do you want to apply the changes? (y/N)"
    if ($apply -eq "y" -or $apply -eq "Y") {
        terraform apply tfplan
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
        
        Write-Host "`nStep 5: Testing Data Loading" -ForegroundColor Cyan
        Pop-Location
        
        # Test the data loading script
        Write-Host "Testing PowerShell data loading script..." -ForegroundColor Yellow
        if (Test-Path "..\scripts\check_and_load_titanic_data.ps1") {
            & "..\scripts\check_and_load_titanic_data.ps1" -ProjectId $ProjectId
        } else {
            Write-Warning "Data loading script not found"
        }
          Write-Host "`nDeployment Test Completed Successfully!" -ForegroundColor Green
        Write-Host "Check your BigQuery dataset at: https://console.cloud.google.com/bigquery?project=$ProjectId" -ForegroundColor Cyan
        Write-Host "Check your Cloud Functions at: https://console.cloud.google.com/functions/list?project=$ProjectId" -ForegroundColor Cyan
    } else {
        Write-Host "Terraform apply skipped by user" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
} finally {
    # Return to original directory
    Pop-Location -ErrorAction SilentlyContinue
}

Write-Host "`nTest deployment script completed!" -ForegroundColor Green
