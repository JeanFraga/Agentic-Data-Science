# Terraform Local Development Helper
# Run this script from the terraform/ directory

# Initialize Terraform with backend configuration
Write-Host "🔧 Initializing Terraform with remote state backend..." -ForegroundColor Yellow
terraform init -backend-config="bucket={project-id}-terraform-state"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Terraform initialized successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run:" -ForegroundColor Cyan
    Write-Host "  terraform plan     # See planned changes" -ForegroundColor White
    Write-Host "  terraform apply    # Apply changes" -ForegroundColor White
    Write-Host "  terraform destroy  # Destroy infrastructure" -ForegroundColor White
} else {
    Write-Host "❌ Terraform initialization failed!" -ForegroundColor Red
}
