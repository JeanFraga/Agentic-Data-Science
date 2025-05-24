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
if ! gcloud alpha bq datasets describe "test_dataset" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "Dataset 'test_dataset' does not exist. Creating dataset and loading Titanic data..."
    
    # Create dataset
    gcloud alpha bq datasets create "test_dataset" \
        --project="$PROJECT_ID" \
        --description="Test dataset for Titanic data"
    
    NEED_DATA=true
else
    echo "Dataset 'test_dataset' exists. Checking for 'titanic' table..."
    
    # Check if table exists
    if ! gcloud alpha bq tables describe "test_dataset.titanic" --project="$PROJECT_ID" >/dev/null 2>&1; then
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
    
    # Create temporary bucket (with timestamp to ensure uniqueness)
    TIMESTAMP=$(date +%s)
    BUCKET_NAME="temp-titanic-data-${TIMESTAMP}"
    
    echo "Creating temporary bucket: gs://$BUCKET_NAME"
    gsutil mb gs://$BUCKET_NAME
    
    echo "Uploading Titanic dataset to temporary bucket..."
    gsutil cp titanic.csv gs://$BUCKET_NAME/
    
    echo "Loading data from bucket to BigQuery..."
    gcloud alpha bq load \
        --project="$PROJECT_ID" \
        --source_format=CSV \
        --skip_leading_rows=1 \
        --autodetect \
        "test_dataset.titanic" \
        "gs://$BUCKET_NAME/titanic.csv"
    
    echo "Cleaning up temporary bucket..."
    gsutil rm -r gs://$BUCKET_NAME
    
    # Clean up local file
    rm -f titanic.csv
    
    echo "Titanic data successfully loaded to BigQuery table 'test_dataset.titanic'"
else
    echo "Titanic data already exists in BigQuery. No action needed."
fi

echo "Script completed successfully."
