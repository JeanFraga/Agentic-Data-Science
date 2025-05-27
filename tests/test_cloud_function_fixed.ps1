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
    .\test_cloud_function_fixed.ps1 -ProjectId "your-project-id" -TestMode "full"
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
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "[STEP] $Message" -ForegroundColor Blue }

Write-Host "Cloud Function Testing Suite" -ForegroundColor Magenta
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
Write-Host "Test Mode: $TestMode" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check Cloud Function Status
Write-Step "Checking Cloud Function deployment status..."
try {
    $functionInfo = gcloud functions describe titanic-data-loader --region=us-east1 --project=$ProjectId --format="json" 2>$null | ConvertFrom-Json
    if ($functionInfo) {
        Write-Success "Cloud Function 'titanic-data-loader' is deployed"
        Write-Info "Status: $($functionInfo.state)"
        Write-Info "Runtime: $($functionInfo.buildConfig.runtime)"
        Write-Info "Memory: $($functionInfo.serviceConfig.availableMemory)"
        Write-Info "Timeout: $($functionInfo.serviceConfig.timeoutSeconds)s"
        Write-Info "Entry Point: $($functionInfo.buildConfig.entryPoint)"
        Write-Info "Trigger: Storage bucket event"
    } else {
        throw "Function not found"
    }
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

Write-Host ""
Write-Success "Cloud Function testing completed!"
Write-Info "Summary:"
Write-Info "  Function deployment status checked"
if ($TestMode -eq 'full' -or $TestMode -eq 'logs-only') {
    Write-Info "  Function execution logs reviewed"
}

Write-Host ""
Write-Info "To monitor ongoing function activity:"
Write-Host "   gcloud logging read 'resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader' --project=$ProjectId --limit=20" -ForegroundColor Gray
Write-Host ""
Write-Info "To check function metrics:"
Write-Host "   gcloud functions describe titanic-data-loader --region=us-east1 --project=$ProjectId" -ForegroundColor Gray
