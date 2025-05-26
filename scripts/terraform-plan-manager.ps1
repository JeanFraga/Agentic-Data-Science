# Terraform Plan Management Script with GCS Storage
# This script demonstrates best practices for storing tfplan files in GCS buckets

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("plan", "apply", "list", "cleanup")]
    [string]$Action,
    
    [string]$Environment = "main",
    [string]$PlanName = $null,
    [string]$ProjectId = $null
)

# Configuration
$TerraformDir = ".\terraform"
$LocalPlanDir = "$TerraformDir\plans"

# Read project ID from terraform.tfvars if not provided
if (-not $ProjectId) {
    $TfVarsPath = "$TerraformDir\terraform.tfvars"
    if (Test-Path $TfVarsPath) {
        $ProjectId = (Get-Content $TfVarsPath | Where-Object { $_ -match 'project_id\s*=\s*"([^"]+)"' } | ForEach-Object { $Matches[1] })
    }
    if (-not $ProjectId) {
        Write-Error "Could not determine project ID. Please specify -ProjectId parameter or ensure terraform.tfvars contains project_id."
        exit 1
    }
}

$PlansBucket = "$ProjectId-terraform-plans"

# Generate plan name if not provided
if (-not $PlanName) {
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $PlanName = "$Environment-$Timestamp"
}

$LocalPlanFile = "$LocalPlanDir\$PlanName.tfplan"
$GcsPlanPath = "gs://$PlansBucket/$Environment/$PlanName.tfplan"

# Ensure local plans directory exists
if (-not (Test-Path $LocalPlanDir)) {
    New-Item -ItemType Directory -Path $LocalPlanDir -Force | Out-Null
}

function Write-Banner {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Test-GcsBucket {
    param([string]$BucketName)
    try {
        $result = gsutil ls "gs://$BucketName/" 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

switch ($Action) {
    "plan" {
        Write-Banner "Creating Terraform Plan: $PlanName"
        Write-Host "Environment: $Environment" -ForegroundColor Green
        Write-Host "Local file: $LocalPlanFile" -ForegroundColor Green
        Write-Host "GCS path: $GcsPlanPath" -ForegroundColor Green
        Write-Host ""
        
        # Change to terraform directory
        Set-Location $TerraformDir
        
        # Create the plan
        Write-Host "Creating Terraform plan..." -ForegroundColor Yellow
        terraform plan -out="$LocalPlanFile"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Plan created successfully!" -ForegroundColor Green
            
            # Check if plans bucket exists
            if (Test-GcsBucket $PlansBucket) {
                Write-Host "Uploading plan to GCS bucket..." -ForegroundColor Yellow
                gsutil cp "$LocalPlanFile" "$GcsPlanPath"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Plan uploaded to GCS: $GcsPlanPath" -ForegroundColor Green
                    
                    # Optionally remove local file for security
                    Write-Host "Removing local plan file for security..." -ForegroundColor Yellow
                    Remove-Item $LocalPlanFile -Force
                    Write-Host "✅ Local plan file removed" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to upload plan to GCS. Plan remains local at: $LocalPlanFile"
                }
            } else {
                Write-Warning "Plans bucket '$PlansBucket' not found. Plan remains local at: $LocalPlanFile"
                Write-Host "Run 'terraform apply' first to create the plans bucket." -ForegroundColor Yellow
            }
        } else {
            Write-Error "Failed to create Terraform plan"
            exit 1
        }
    }
    
    "apply" {
        Write-Banner "Applying Terraform Plan: $PlanName"
        Write-Host "Environment: $Environment" -ForegroundColor Green
        Write-Host "GCS path: $GcsPlanPath" -ForegroundColor Green
        Write-Host ""
        
        # Change to terraform directory
        Set-Location $TerraformDir
        
        # Download plan from GCS if it doesn't exist locally
        if (-not (Test-Path $LocalPlanFile)) {
            if (Test-GcsBucket $PlansBucket) {
                Write-Host "Downloading plan from GCS..." -ForegroundColor Yellow
                gsutil cp "$GcsPlanPath" "$LocalPlanFile"
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Failed to download plan from GCS: $GcsPlanPath"
                    exit 1
                }
                Write-Host "✅ Plan downloaded from GCS" -ForegroundColor Green
            } else {
                Write-Error "Plan file not found locally and plans bucket doesn't exist: $LocalPlanFile"
                exit 1
            }
        }
        
        # Apply the plan
        Write-Host "Applying Terraform plan..." -ForegroundColor Yellow
        terraform apply "$LocalPlanFile"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Plan applied successfully!" -ForegroundColor Green
            
            # Clean up local and remote plan files after successful apply
            Write-Host "Cleaning up plan files..." -ForegroundColor Yellow
            if (Test-Path $LocalPlanFile) {
                Remove-Item $LocalPlanFile -Force
            }
            gsutil rm "$GcsPlanPath" 2>$null
            Write-Host "✅ Plan files cleaned up" -ForegroundColor Green
        } else {
            Write-Error "Failed to apply Terraform plan"
            exit 1
        }
    }
    
    "list" {
        Write-Banner "Listing Available Plans"
        Write-Host "Environment: $Environment" -ForegroundColor Green
        Write-Host "Bucket: $PlansBucket" -ForegroundColor Green
        Write-Host ""
        
        if (Test-GcsBucket $PlansBucket) {
            Write-Host "Plans in GCS bucket:" -ForegroundColor Yellow
            gsutil ls "gs://$PlansBucket/$Environment/"
        } else {
            Write-Warning "Plans bucket '$PlansBucket' not found"
        }
        
        Write-Host "`nLocal plans:" -ForegroundColor Yellow
        if (Test-Path $LocalPlanDir) {
            Get-ChildItem "$LocalPlanDir\*.tfplan" | ForEach-Object {
                Write-Host "  $($_.Name)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  No local plans found" -ForegroundColor Gray
        }
    }
    
    "cleanup" {
        Write-Banner "Cleaning Up Old Plans"
        Write-Host "Environment: $Environment" -ForegroundColor Green
        
        # Clean up local plans older than 7 days
        Write-Host "Cleaning local plans older than 7 days..." -ForegroundColor Yellow
        if (Test-Path $LocalPlanDir) {
            Get-ChildItem "$LocalPlanDir\*.tfplan" | Where-Object { 
                $_.LastWriteTime -lt (Get-Date).AddDays(-7) 
            } | ForEach-Object {
                Write-Host "  Removing: $($_.Name)" -ForegroundColor Gray
                Remove-Item $_.FullName -Force
            }
        }
        
        Write-Host "✅ Local cleanup complete" -ForegroundColor Green
        Write-Host "Note: GCS plans are automatically cleaned up by bucket lifecycle policies (30 days)" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 Plan management complete!" -ForegroundColor Green
