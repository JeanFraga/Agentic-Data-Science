#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitor Cloud Function health and performance over time

.DESCRIPTION
    This script provides ongoing monitoring of the Cloud Function including:
    - Real-time log streaming
    - Function metrics and performance
    - Error rate monitoring
    - Resource utilization tracking

.PARAMETER ProjectId
    The GCP project ID to monitor

.PARAMETER MonitorDuration
    How long to monitor in minutes (default: 10)

.PARAMETER ShowMetrics
    Include detailed metrics in monitoring

.EXAMPLE
    .\monitor_cloud_function.ps1 -ProjectId "your-project-id" -MonitorDuration 5
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [int]$MonitorDuration = 10,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowMetrics
)

# Color functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Metric { param($Message) Write-Host "📊 $Message" -ForegroundColor Magenta }

Write-Host "🔍 Cloud Function Health Monitor" -ForegroundColor Magenta
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
Write-Host "Duration: $MonitorDuration minutes" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
$endTime = $startTime.AddMinutes($MonitorDuration)

# Function to get metrics
function Get-FunctionMetrics {
    try {
        # Get function status
        $functionInfo = gcloud functions describe titanic-data-loader --region=us-central1 --project=$ProjectId --format="json" 2>$null | ConvertFrom-Json
        
        if ($functionInfo) {
            Write-Success "Function Status: $($functionInfo.status)"
            Write-Info "Last Update: $($functionInfo.updateTime)"
            Write-Info "Version: $($functionInfo.versionId)"
        }
        
        # Get recent execution count
        $recentLogs = gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=`"$((Get-Date).AddMinutes(-5).ToString('yyyy-MM-ddTHH:mm:ssZ'))`"" --project=$ProjectId --format="json" 2>$null | ConvertFrom-Json
        
        if ($recentLogs) {
            $executions = $recentLogs.Count
            $errors = ($recentLogs | Where-Object { $_.severity -eq "ERROR" }).Count
            $warnings = ($recentLogs | Where-Object { $_.severity -eq "WARNING" }).Count
            
            Write-Metric "Recent activity (last 5 min): $executions executions"
            if ($errors -gt 0) { Write-Error "Errors: $errors" }
            if ($warnings -gt 0) { Write-Warning "Warnings: $warnings" }
        } else {
            Write-Info "No recent activity detected"
        }
        
    } catch {
        Write-Warning "Could not retrieve metrics: $($_.Exception.Message)"
    }
}

# Function to show recent logs
function Show-RecentLogs {
    param([int]$Minutes = 2)
    
    try {
        $logs = gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=`"$((Get-Date).AddMinutes(-$Minutes).ToString('yyyy-MM-ddTHH:mm:ssZ'))`"" --project=$ProjectId --limit=10 --format="json" 2>$null | ConvertFrom-Json
        
        if ($logs.Count -gt 0) {
            Write-Info "Recent logs (last $Minutes minutes):"
            foreach ($log in $logs | Sort-Object timestamp) {
                $timestamp = ([DateTime]$log.timestamp).ToString("HH:mm:ss")
                $severity = $log.severity
                $message = $log.textPayload -or $log.jsonPayload.message -or "No message"
                
                $color = switch ($severity) {
                    "ERROR" { "Red" }
                    "WARNING" { "Yellow" }
                    "INFO" { "White" }
                    default { "Gray" }
                }
                Write-Host "  [$timestamp] [$severity] $message" -ForegroundColor $color
            }
        }
    } catch {
        Write-Warning "Could not retrieve recent logs"
    }
}

# Initial status check
Write-Info "Initial function status check..."
Get-FunctionMetrics

if ($ShowMetrics) {
    Write-Info "Detailed metrics enabled"
}

# Monitoring loop
$iteration = 0
while ((Get-Date) -lt $endTime) {
    $iteration++
    $currentTime = Get-Date
    $remainingMinutes = [math]::Round(($endTime - $currentTime).TotalMinutes, 1)
    
    Write-Host ""
    Write-Host "📅 Monitor Check #$iteration - $remainingMinutes minutes remaining" -ForegroundColor Blue
    Write-Host "Time: $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    
    # Show recent logs
    Show-RecentLogs -Minutes 2
    
    # Show metrics every 3rd iteration or if requested
    if ($iteration % 3 -eq 0 -or $ShowMetrics) {
        Write-Host ""
        Get-FunctionMetrics
    }
    
    # Check for bucket activity
    try {
        $bucketName = "$ProjectId-temp-bucket"
        $bucketObjects = gsutil ls gs://$bucketName/ 2>$null
        if ($bucketObjects) {
            $objectCount = ($bucketObjects | Measure-Object).Count
            Write-Info "Bucket objects: $objectCount files in gs://$bucketName/"
        }
    } catch {
        # Ignore bucket check errors
    }
    
    # Wait before next check (30 seconds)
    if ((Get-Date) -lt $endTime.AddSeconds(-30)) {
        Write-Host "⏳ Waiting 30 seconds for next check..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    } else {
        break
    }
}

Write-Host ""
Write-Success "🏁 Monitoring completed"
Write-Info "Total monitoring time: $((Get-Date) - $startTime | ForEach-Object { [math]::Round($_.TotalMinutes, 1) }) minutes"

# Final summary
Write-Host ""
Write-Info "📋 Final Summary:"
Get-FunctionMetrics
Show-RecentLogs -Minutes 10

Write-Host ""
Write-Info "💡 Useful commands for continued monitoring:"
Write-Host "   # Stream live logs:" -ForegroundColor Gray
Write-Host "   gcloud logging tail 'resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader' --project=$ProjectId" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Check function metrics:" -ForegroundColor Gray
Write-Host "   gcloud functions describe titanic-data-loader --region=us-central1 --project=$ProjectId" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Test the function:" -ForegroundColor Gray
Write-Host "   gsutil cp test_file.csv gs://$ProjectId-temp-bucket/titanic.csv" -ForegroundColor Gray
