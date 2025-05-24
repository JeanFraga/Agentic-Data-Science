# PowerShell script to check BigQuery dataset and load Titanic data if needed
# Usage: .\check_and_load_titanic_data.ps1 -ProjectId "your-project-id"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId
)

# Set error action to stop on any error
$ErrorActionPreference = "Stop"

Write-Host "Checking BigQuery dataset and Titanic data for project: $ProjectId" -ForegroundColor Green

# Check if dataset exists
Write-Host "Checking if dataset 'test_dataset' exists..." -ForegroundColor Yellow
try {
    $datasetInfo = bq show --project_id="$ProjectId" "test_dataset" 2>$null
    $datasetExists = $LASTEXITCODE -eq 0
} catch {
    $datasetExists = $false
}

$needData = $false

if (-not $datasetExists) {
    Write-Host "Dataset 'test_dataset' does not exist. Creating dataset..." -ForegroundColor Yellow
    
    # Create dataset
    bq mk --project_id="$ProjectId" --description="Test dataset for Titanic data" "test_dataset"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dataset 'test_dataset' created successfully" -ForegroundColor Green
    } else {
        Write-Error "Failed to create dataset 'test_dataset'"
    }
    
    $needData = $true
} else {
    Write-Host "Dataset 'test_dataset' exists. Checking for 'titanic' table..." -ForegroundColor Green
    
    # Check if table exists
    try {
        $tableInfo = bq show --project_id="$ProjectId" "test_dataset.titanic" 2>$null
        $tableExists = $LASTEXITCODE -eq 0
    } catch {
        $tableExists = $false
    }
    
    if (-not $tableExists) {
        Write-Host "Table 'titanic' does not exist in dataset 'test_dataset'." -ForegroundColor Yellow
        $needData = $true
    } else {
        Write-Host "Table 'titanic' already exists in dataset 'test_dataset'." -ForegroundColor Green
        $needData = $false
    }
}

# Download and upload data if needed
if ($needData) {
    Write-Host "Downloading Titanic dataset..." -ForegroundColor Yellow
    
    # Download the Titanic dataset
    $titanicUrl = "https://raw.githubusercontent.com/datasciencedojo/datasets/refs/heads/master/titanic.csv"
    $localFile = "titanic.csv"
    
    try {
        Invoke-WebRequest -Uri $titanicUrl -OutFile $localFile
        Write-Host "Titanic dataset downloaded successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download Titanic dataset: $_"
    }
    
    # Use the existing temp bucket created by Terraform
    $bucketName = "$ProjectId-temp-bucket"
    
    Write-Host "Uploading Titanic dataset to temp bucket: gs://$bucketName" -ForegroundColor Yellow
    Write-Host "This will trigger the Cloud Function to automatically load data to BigQuery..." -ForegroundColor Cyan
    
    try {
        gsutil cp $localFile "gs://$bucketName/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "File uploaded successfully! Cloud Function should process it shortly." -ForegroundColor Green
        } else {
            Write-Error "Failed to upload file to bucket"
        }
    } catch {
        Write-Error "Failed to upload file to bucket: $_"
    }
    
    # Clean up local file
    if (Test-Path $localFile) {
        Remove-Item $localFile -Force
        Write-Host "Cleaned up local file" -ForegroundColor Gray
    }
    
    Write-Host "Waiting for Cloud Function to process the data..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Verify the table was created
    Write-Host "Verifying table creation..." -ForegroundColor Yellow
    $maxRetries = 6
    $retryCount = 0
    
    do {
        Start-Sleep -Seconds 5
        try {
            $tableInfo = bq show --project_id="$ProjectId" "test_dataset.titanic" 2>$null
            $tableExists = $LASTEXITCODE -eq 0
        } catch {
            $tableExists = $false
        }
        
        $retryCount++
        if (-not $tableExists -and $retryCount -lt $maxRetries) {
            Write-Host "Table not ready yet, waiting... (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
        }
    } while (-not $tableExists -and $retryCount -lt $maxRetries)
    
    if ($tableExists) {
        Write-Host "SUCCESS! Titanic table created and data loaded!" -ForegroundColor Green
        
        # Get row count
        try {
            $rowCount = bq query --use_legacy_sql=false --project_id="$ProjectId" --format=csv "SELECT COUNT(*) as count FROM test_dataset.titanic" | Select-Object -Skip 1
            Write-Host "Table contains $rowCount rows of data" -ForegroundColor Green
        } catch {
            Write-Host "Table created (could not get row count)" -ForegroundColor Green
        }
    } else {
        Write-Warning "Table creation may have failed or is taking longer than expected. Check Cloud Function logs."
    }
} else {
    Write-Host "All data is already in place!" -ForegroundColor Green
}

Write-Host "Script completed successfully!" -ForegroundColor Green
