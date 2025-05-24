#!/bin/bash
# Validation script to verify the Agentic Data Science infrastructure
# Usage: ./validate_deployment.sh <project_id>

set -e

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID is required as first argument"
    echo "Usage: ./validate_deployment.sh <project_id>"
    exit 1
fi

echo "🔍 Validating Agentic Data Science deployment for project: $PROJECT_ID"

# Function to check if a resource exists
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local command=$3
    
    echo -n "  Checking $resource_type '$resource_name'... "
    if eval $command >/dev/null 2>&1; then
        echo "✅ EXISTS"
        return 0
    else
        echo "❌ NOT FOUND"
        return 1
    fi
}

echo ""
echo "📦 Checking Cloud Storage resources:"
check_resource "Terraform State Bucket" "${PROJECT_ID}-terraform-state" \
    "gsutil ls gs://${PROJECT_ID}-terraform-state"

check_resource "Temp Bucket" "${PROJECT_ID}-temp-bucket" \
    "gsutil ls gs://${PROJECT_ID}-temp-bucket"

check_resource "Function Source Bucket" "${PROJECT_ID}-function-source" \
    "gsutil ls gs://${PROJECT_ID}-function-source"

echo ""
echo "📊 Checking BigQuery resources:"
check_resource "Dataset" "test_dataset" \
    "gcloud alpha bq datasets describe test_dataset --project=$PROJECT_ID"

echo ""
echo "⚡ Checking Cloud Functions:"
check_resource "Function" "titanic-data-loader" \
    "gcloud functions describe titanic-data-loader --region=us-central1 --project=$PROJECT_ID --gen2"

echo ""
echo "🔐 Checking Service Account:"
check_resource "Service Account" "titanic-loader-sa" \
    "gcloud iam service-accounts describe titanic-loader-sa@${PROJECT_ID}.iam.gserviceaccount.com --project=$PROJECT_ID"

echo ""
echo "🧪 Testing Cloud Function trigger:"
echo "  Uploading test file to trigger Cloud Function..."

# Create a simple test CSV
cat > test_titanic.csv << EOF
PassengerId,Survived,Pclass,Name,Sex,Age,SibSp,Parch,Ticket,Fare,Cabin,Embarked
1,0,3,"Test, Mr. Test",male,22,1,0,A/5 21171,7.25,,S
2,1,1,"Test, Mrs. Test",female,38,1,0,PC 17599,71.2833,C85,C
EOF

# Upload to temp bucket (this should trigger the Cloud Function)
gsutil cp test_titanic.csv gs://${PROJECT_ID}-temp-bucket/titanic.csv

echo "  Waiting for Cloud Function to process..."
sleep 45

# Check if table was created/updated
if check_resource "Titanic Table" "test_dataset.titanic" \
    "gcloud alpha bq tables describe test_dataset.titanic --project=$PROJECT_ID"; then
    
    echo "  📊 Getting table statistics..."
    ROW_COUNT=$(gcloud alpha bq query --project="$PROJECT_ID" --use_legacy_sql=false --format="value(f0_)" \
        "SELECT COUNT(*) FROM \`$PROJECT_ID.test_dataset.titanic\`" 2>/dev/null || echo "0")
    
    COLUMN_COUNT=$(gcloud alpha bq query --project="$PROJECT_ID" --use_legacy_sql=false --format="value(f0_)" \
        "SELECT COUNT(*) FROM \`$PROJECT_ID.test_dataset.titanic\` LIMIT 0" 2>/dev/null | wc -l || echo "0")
    
    echo "  📈 Table contains $ROW_COUNT rows"
    echo "  📋 Table schema validation..."
    
    # Show table schema
    gcloud alpha bq tables describe test_dataset.titanic --project=$PROJECT_ID --format="table(schema[].name,schema[].type)" 2>/dev/null || echo "  ⚠️  Could not retrieve schema"
fi

# Clean up test file
rm -f test_titanic.csv
gsutil rm gs://${PROJECT_ID}-temp-bucket/titanic.csv 2>/dev/null || true

echo ""
echo "🔍 Checking Cloud Function logs:"
echo "  Recent function executions:"
gcloud functions logs read titanic-data-loader --region=us-central1 --project=$PROJECT_ID --limit=10 --format="table(timestamp,severity,textPayload)" 2>/dev/null || echo "  ⚠️  Could not retrieve logs"

echo ""
echo "✅ Validation completed!"
echo ""
echo "🔗 Useful links:"
echo "  📊 BigQuery Console: https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
echo "  ⚡ Cloud Functions Console: https://console.cloud.google.com/functions/list?project=$PROJECT_ID"
echo "  📦 Cloud Storage Console: https://console.cloud.google.com/storage/browser?project=$PROJECT_ID"
echo "  📋 Terraform State: gs://${PROJECT_ID}-terraform-state"
echo ""
echo "🎯 Next steps:"
echo "  1. Upload titanic.csv to gs://${PROJECT_ID}-temp-bucket/ to test the full pipeline"
echo "  2. Monitor Cloud Function logs for processing status"
echo "  3. Query the BigQuery table to analyze the data"
