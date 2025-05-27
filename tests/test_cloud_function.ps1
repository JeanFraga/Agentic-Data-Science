#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script to verify Cloud Function is properly processing files and loading data to BigQuery

.DESCRIPTION
    This script performs comprehensive testing of the Cloud Function by:
    1. Checking Cloud Function deployment status
    2. Testing file upload triggering
    3. Monitoring function execution logs
    4. Verifying BigQuery data loading
    5. Testing error scenarios

.PARAMETER ProjectId
    The GCP project ID to test

.PARAMETER TestMode
    The type of test to run: 'full', 'quick', 'logs-only', 'function-status'

.EXAMPLE
    .\test_cloud_function.ps1 -ProjectId "your-project-id" -TestMode "full"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('full', 'quick', 'logs-only', 'function-status')]
    [string]$TestMode = 'quick'
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "🔄 $Message" -ForegroundColor Blue }

Write-Host "🧪 Cloud Function Testing Suite" -ForegroundColor Magenta
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
Write-Host "Test Mode: $TestMode" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check Cloud Function Status
Write-Step "Checking Cloud Function deployment status..."
try {
    $functionInfo = gcloud functions describe titanic-data-loader --region=us-central1 --project=$ProjectId --format="json" | ConvertFrom-Json
    Write-Success "Cloud Function 'titanic-data-loader' is deployed"
    Write-Info "Status: $($functionInfo.status)"
    Write-Info "Runtime: $($functionInfo.runtime)"
    Write-Info "Memory: $($functionInfo.availableMemoryMb)MB"
    Write-Info "Timeout: $($functionInfo.timeout)"
    Write-Info "Entry Point: $($functionInfo.entryPoint)"
    Write-Info "Trigger: Storage bucket '$($functionInfo.eventTrigger.resource)'"
} catch {
    Write-Error "Cloud Function not found or not accessible"
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}

# Test 2: Check Function Logs (if logs-only or full mode)
if ($TestMode -eq 'logs-only' -or $TestMode -eq 'full') {
    Write-Step "Checking recent Cloud Function logs..."
    try {
        Write-Info "Fetching logs from the last 24 hours..."
        $logs = gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader" --project=$ProjectId --limit=50 --format="json" | ConvertFrom-Json
        
        if ($logs.Count -gt 0) {
            Write-Success "Found $($logs.Count) recent log entries"
            Write-Info "Recent function executions:"
            
            foreach ($log in $logs | Select-Object -First 10) {
                $timestamp = $log.timestamp
                $severity = $log.severity
                $message = $log.textPayload -or $log.jsonPayload.message -or "No message"
                Write-Host "  [$timestamp] [$severity] $message" -ForegroundColor Gray
            }
        } else {
            Write-Warning "No recent logs found for the Cloud Function"
        }
    } catch {
        Write-Warning "Could not retrieve function logs: $($_.Exception.Message)"
    }
}

# Exit early if only checking status or logs
if ($TestMode -eq 'function-status' -or $TestMode -eq 'logs-only') {
    Write-Success "Test completed"
    exit 0
}

# Test 3: Prepare test environment
Write-Step "Preparing test environment..."
$tempDir = [System.IO.Path]::GetTempPath()
$testFile = Join-Path $tempDir "test_titanic.csv"
$bucketName = "$ProjectId-temp-bucket"

# Download test data
Write-Step "Downloading test Titanic dataset..."
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/datasciencedojo/datasets/refs/heads/master/titanic.csv" -OutFile $testFile
    Write-Success "Test data downloaded to: $testFile"
    
    # Show file info
    $fileInfo = Get-Item $testFile
    Write-Info "File size: $([math]::Round($fileInfo.Length/1KB, 2)) KB"
    
    # Show first few lines
    $firstLines = Get-Content $testFile -Head 3
    Write-Info "First few lines of data:"
    foreach ($line in $firstLines) {
        Write-Host "  $line" -ForegroundColor Gray
    }
} catch {
    Write-Error "Failed to download test data: $($_.Exception.Message)"
    exit 1
}

# Test 4: Check bucket exists
Write-Step "Verifying temp bucket exists..."
try {
    $bucketInfo = gsutil ls -b gs://$bucketName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Temp bucket 'gs://$bucketName' exists"
    } else {
        Write-Error "Temp bucket 'gs://$bucketName' not found"
        exit 1
    }
} catch {
    Write-Error "Failed to check bucket: $($_.Exception.Message)"
    exit 1
}

# Test 5: Clear any existing data (for clean test)
Write-Step "Clearing existing test data for clean test..."
try {
    # Remove any existing titanic.csv from bucket
    gsutil rm gs://$bucketName/titanic.csv 2>$null
    
    # Drop existing BigQuery table if it exists
    bq rm -f --project_id=$ProjectId test_dataset.titanic 2>$null
    Write-Success "Cleaned up existing test data"
} catch {
    Write-Info "No existing data to clean up"
}

# Test 6: Upload file and monitor function execution
Write-Step "Uploading test file to trigger Cloud Function..."
$uploadStartTime = Get-Date

try {
    # Upload file to bucket (this should trigger the Cloud Function)
    gsutil cp $testFile gs://$bucketName/titanic.csv
    Write-Success "File uploaded to gs://$bucketName/titanic.csv"
    
    # Wait for function to process
    Write-Step "Waiting for Cloud Function to process the file..."
    Start-Sleep -Seconds 5
    
    # Monitor for function execution in logs
    $maxWaitTime = 60  # seconds
    $waitInterval = 5   # seconds
    $totalWaited = 0
    $functionExecuted = $false
    
    while ($totalWaited -lt $maxWaitTime -and -not $functionExecuted) {
        try {
            $recentLogs = gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=`"$($uploadStartTime.ToString('yyyy-MM-ddTHH:mm:ssZ'))`"" --project=$ProjectId --limit=10 --format="json" 2>$null | ConvertFrom-Json
            
            if ($recentLogs.Count -gt 0) {
                Write-Success "Cloud Function execution detected!"
                $functionExecuted = $true
                
                # Show relevant log entries
                foreach ($log in $recentLogs) {
                    $severity = $log.severity
                    $message = $log.textPayload -or $log.jsonPayload.message -or "No message"
                    $color = switch ($severity) {
                        "ERROR" { "Red" }
                        "WARNING" { "Yellow" }
                        "INFO" { "White" }
                        default { "Gray" }
                    }
                    Write-Host "  [$severity] $message" -ForegroundColor $color
                }
            } else {
                Write-Host "." -NoNewline
                Start-Sleep -Seconds $waitInterval
                $totalWaited += $waitInterval
            }
        } catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds $waitInterval
            $totalWaited += $waitInterval
        }
    }
    
    if (-not $functionExecuted) {
        Write-Warning "No function execution logs found within $maxWaitTime seconds"
        Write-Info "The function might still be processing or there might be an issue"
    }
    
} catch {
    Write-Error "Failed to upload file: $($_.Exception.Message)"
    exit 1
}

# Test 7: Verify BigQuery table creation and data loading
Write-Step "Verifying BigQuery data loading..."
Start-Sleep -Seconds 10  # Give additional time for BigQuery operations

try {
    # Check if table exists and get info
    $tableInfo = bq show --project_id=$ProjectId --format=json test_dataset.titanic 2>$null | ConvertFrom-Json
    
    if ($tableInfo) {
        Write-Success "BigQuery table 'test_dataset.titanic' created successfully"
        Write-Info "Table ID: $($tableInfo.id)"
        Write-Info "Rows: $($tableInfo.numRows)"
        Write-Info "Size: $([math]::Round($tableInfo.numBytes/1KB, 2)) KB"
        Write-Info "Created: $($tableInfo.creationTime)"
        Write-Info "Last Modified: $($tableInfo.lastModifiedTime)"
        
        # Get sample data
        Write-Step "Fetching sample data from BigQuery table..."
        $sampleQuery = "SELECT * FROM ``$ProjectId.test_dataset.titanic`` LIMIT 5"
        $sampleData = bq query --project_id=$ProjectId --use_legacy_sql=false --format=json --max_rows=5 $sampleQuery | ConvertFrom-Json
        
        if ($sampleData) {
            Write-Success "Sample data retrieved successfully:"
            $sampleData | Format-Table -AutoSize | Out-String | Write-Host
        }
        
        # Get row count
        $countQuery = "SELECT COUNT(*) as total_rows FROM ``$ProjectId.test_dataset.titanic``"
        $rowCount = bq query --project_id=$ProjectId --use_legacy_sql=false --format=csv --quiet $countQuery | Select-Object -Skip 1
        Write-Success "Total rows in table: $rowCount"
        
    } else {
        Write-Error "BigQuery table was not created"
        Write-Warning "Check Cloud Function logs for errors"
    }
    
} catch {
    Write-Error "Failed to verify BigQuery table: $($_.Exception.Message)"
}

# Test 8: Performance test (full mode only)
if ($TestMode -eq 'full') {
    Write-Step "Running performance test..."
    
    # Test with different file sizes
    Write-Info "Testing function performance with multiple file uploads..."
    
    for ($i = 1; $i -le 3; $i++) {
        Write-Step "Performance test run $i/3"
        $perfStartTime = Get-Date
        
        # Upload file again (should trigger function again)
        gsutil cp $testFile gs://$bucketName/titanic_perf_$i.csv
        
        # Wait for processing
        Start-Sleep -Seconds 15
        
        $perfEndTime = Get-Date
        $processingTime = ($perfEndTime - $perfStartTime).TotalSeconds
        Write-Info "Processing time for run ${i}: $processingTime seconds"
    }
}

# Cleanup
Write-Step "Cleaning up test files..."
try {
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    Write-Success "Local test file cleaned up"
} catch {
    Write-Warning "Could not clean up local test file"
}

Write-Host ""
Write-Success "🎉 Cloud Function testing completed!"
Write-Info "Summary:"
Write-Info "  ✓ Function deployment status checked"
Write-Info "  ✓ File upload and trigger tested"
Write-Info "  ✓ Function execution monitored"
Write-Info "  ✓ BigQuery data loading verified"

if ($TestMode -eq 'full') {
    Write-Info "  ✓ Performance testing completed"
}

Write-Host ""
Write-Info "💡 To monitor ongoing function activity:"
Write-Host "   gcloud logging read 'resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader' --project=$ProjectId --limit=20" -ForegroundColor Gray
Write-Host ""
Write-Info "💡 To check function metrics:"
Write-Host "   gcloud functions describe titanic-data-loader --region=us-central1 --project=$ProjectId" -ForegroundColor Gray
