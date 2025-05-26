# PowerShell script to handle Secret Manager import for local development
# This script mirrors the logic in the GitHub Actions workflow

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId
)

Write-Host "Checking for existing Secret Manager resources..." -ForegroundColor Green

# Change to terraform directory
Set-Location "h:\My Drive\Github\Agentic Data Science\terraform"

try {
    # Check if the secret exists
    $secretExists = $false
    try {
        gcloud secrets describe gemini-api-key --project=$ProjectId 2>$null
        if ($LASTEXITCODE -eq 0) {
            $secretExists = $true
            Write-Host "Secret 'gemini-api-key' already exists" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Secret 'gemini-api-key' does not exist" -ForegroundColor Green
    }

    if ($secretExists) {
        Write-Host "Attempting to import existing secret..." -ForegroundColor Yellow
        
        # Try to import the secret
        try {
            terraform import google_secret_manager_secret.gemini_api_key "projects/$ProjectId/secrets/gemini-api-key"
            Write-Host "Successfully imported secret" -ForegroundColor Green
        }
        catch {
            Write-Host "Secret import failed or resource already in state: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        # Try to import the secret version
        try {
            $versionId = gcloud secrets versions list gemini-api-key --project=$ProjectId --limit=1 --format="value(name)" 2>$null
            if ($versionId -and $LASTEXITCODE -eq 0) {
                Write-Host "Attempting to import secret version: $versionId" -ForegroundColor Yellow
                terraform import google_secret_manager_secret_version.gemini_api_key_version "projects/$ProjectId/secrets/gemini-api-key/versions/$versionId"
                Write-Host "Successfully imported secret version" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Secret version import failed or already in state: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Secret does not exist - Terraform will create it" -ForegroundColor Green
    }

    Write-Host "`nRunning Terraform plan to check configuration..." -ForegroundColor Green
    terraform plan -no-color

} catch {
    Write-Error "Error occurred: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nSecret Manager import process completed!" -ForegroundColor Green
