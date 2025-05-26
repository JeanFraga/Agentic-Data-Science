#!/bin/bash

# Script to check BigQuery dataset and load Titanic data if needed
# Usage: ./check_and_load_titanic_data.sh <project_id>

set -e  # Exit on any error

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
    echo "Error: Project ID is required as first argument"
    exit 1
fi

echo "Checking BigQuery dataset and Titanic data for project: $PROJECT_ID"

# Check if dataset exists
if ! bq show --project_id="$PROJECT_ID" "test_dataset" >/dev/null 2>&1; then
    echo "Dataset 'test_dataset' does not exist. Creating dataset and loading Titanic data..."
    
    # Create dataset
    bq mk --project_id="$PROJECT_ID" --description="Test dataset for Titanic data" "test_dataset"
    
    NEED_DATA=true
else
    echo "Dataset 'test_dataset' exists. Checking for 'titanic' table..."
    
    # Check if table exists
    if ! bq show --project_id="$PROJECT_ID" "test_dataset.titanic" >/dev/null 2>&1; then
        echo "Table 'titanic' does not exist in dataset 'test_dataset'."
        NEED_DATA=true
    else
        echo "Table 'titanic' already exists in dataset 'test_dataset'."
        NEED_DATA=false
    fi
fi

# Download and upload data if needed
if [ "$NEED_DATA" = "true" ]; then
    echo "Downloading Titanic dataset..."
    curl -o titanic.csv "https://raw.githubusercontent.com/datasciencedojo/datasets/refs/heads/master/titanic.csv"
    
    # Use the existing temp bucket created by Terraform
    BUCKET_NAME="${PROJECT_ID}-temp-bucket"
    
    echo "Uploading Titanic dataset to temp bucket: gs://$BUCKET_NAME"
    echo "This will trigger the Cloud Function to automatically load data to BigQuery..."
    gsutil cp titanic.csv gs://$BUCKET_NAME/
    
    # Wait a moment for the Cloud Function to process
    echo "Waiting for Cloud Function to process the file..."
    sleep 30
    
    # Check if the table was created by the Cloud Function
    echo "Verifying that data was loaded by Cloud Function..."
    
    # First, wait and check logs for function execution
    echo "Checking Cloud Function execution logs..."
    UPLOAD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    sleep 5  # Brief wait before checking logs
    
    # Check for recent function execution
    FUNCTION_LOGS=$(gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=\"$(date -u -d '2 minutes ago' +%Y-%m-%dT%H:%M:%SZ)\"" --project="$PROJECT_ID" --limit=5 --format="value(textPayload)" 2>/dev/null || echo "")
    
    if [ -n "$FUNCTION_LOGS" ]; then
        echo "📋 Recent Cloud Function activity detected:"
        echo "$FUNCTION_LOGS" | head -3
    else
        echo "⚠️  No recent Cloud Function logs found"
    fi
    
    # Wait for function to complete processing
    echo "Waiting for Cloud Function processing to complete..."
    sleep 25
    
    # Check if BigQuery table was created (using standard bq command instead of alpha)
    if bq show --project_id="$PROJECT_ID" "test_dataset.titanic" >/dev/null 2>&1; then
        echo "✅ Cloud Function successfully loaded data to BigQuery table 'test_dataset.titanic'"
        
        # Get row count using standard bq query
        ROW_COUNT=$(bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --format="csv" --quiet "SELECT COUNT(*) FROM \`$PROJECT_ID.test_dataset.titanic\`" | tail -n 1)
        echo "📊 Table contains $ROW_COUNT rows"
        
        # Verify data quality
        if [ "$ROW_COUNT" -gt 800 ]; then
            echo "✅ Data loading successful - expected row count achieved"
        else
            echo "⚠️  Warning: Row count ($ROW_COUNT) seems low for Titanic dataset"
        fi
    else
        echo "❌ Cloud Function may have failed. Falling back to direct BigQuery load..."
        bq load \
            --project_id="$PROJECT_ID" \
            --source_format=CSV \
            --skip_leading_rows=1 \
            --autodetect \
            "test_dataset.titanic" \
            "gs://$BUCKET_NAME/titanic.csv"
        echo "✅ Data loaded directly to BigQuery as fallback"
    fi
    
    # Clean up local file
    rm -f titanic.csv
    
    echo "Titanic data successfully available in BigQuery table 'test_dataset.titanic'"
else
    echo "Titanic data already exists in BigQuery. No action needed."
fi

echo "Script completed successfully."
