# Quick test to verify BigQuery data after Gen 2 Cloud Function execution
# PowerShell script to check data in BigQuery

Write-Host "=== Checking BigQuery Data after Gen 2 Cloud Function Migration ===" -ForegroundColor Green

try {
    # Query BigQuery to check if data was loaded
    $result = gcloud query --use_legacy_sql=false --project_id=agentic-data-science-460701 --format="value(f0_)" "SELECT COUNT(*) FROM \`agentic-data-science-460701.test_dataset.titanic\`" 2>$null
    
    if ($result) {
        Write-Host "✅ SUCCESS: Found $result rows in BigQuery table!" -ForegroundColor Green
        
        # Get sample data
        Write-Host "`n--- Sample Data ---" -ForegroundColor Yellow
        gcloud query --use_legacy_sql=false --project_id=agentic-data-science-460701 --format="table" "SELECT * FROM \`agentic-data-science-460701.test_dataset.titanic\` LIMIT 3" 2>$null
          Write-Host "`n✅ Gen 2 Cloud Function is working correctly!" -ForegroundColor Green
    } else {
        Write-Host "❌ No data found in BigQuery table" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error querying BigQuery: $_" -ForegroundColor Red
    Write-Host "Checking table existence..." -ForegroundColor Yellow
    
    try {
        $tables = gcloud bq ls --project_id=agentic-data-science-460701 test_dataset 2>$null
        Write-Host "Tables in dataset: $tables" -ForegroundColor White
    } catch {
        Write-Host "Error checking dataset: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
