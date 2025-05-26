#!/bin/bash

# Quick Cloud Function test script
# Usage: ./test_cloud_function_quick.sh <project_id>

set -e

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID is required as first argument"
    echo "Usage: $0 <project_id>"
    exit 1
fi

echo "🧪 Quick Cloud Function Test"
echo "Project: $PROJECT_ID"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_step() { echo -e "${BLUE}🔄 $1${NC}"; }

# Test 1: Check if Cloud Function exists
print_step "Checking Cloud Function status..."
if gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --quiet >/dev/null 2>&1; then
    print_success "Cloud Function 'titanic-data-loader' is deployed"
    
    # Get function info
    FUNCTION_STATUS=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(status)")
    FUNCTION_TRIGGER=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(eventTrigger.resource)")
    
    print_info "Status: $FUNCTION_STATUS"
    print_info "Trigger bucket: $FUNCTION_TRIGGER"
else
    print_error "Cloud Function 'titanic-data-loader' not found or not accessible"
    exit 1
fi

# Test 2: Check recent function logs
print_step "Checking recent function execution logs..."
RECENT_LOGS=$(gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader" --project="$PROJECT_ID" --limit=5 --format="table(timestamp,severity,textPayload)" 2>/dev/null || echo "")

if [ -n "$RECENT_LOGS" ]; then
    print_success "Recent function logs found:"
    echo "$RECENT_LOGS"
else
    print_warning "No recent logs found (function may not have been triggered recently)"
fi

# Test 3: Quick file upload test
print_step "Performing quick file upload test..."

# Download test file
TEMP_FILE="/tmp/test_titanic_$(date +%s).csv"
if curl -s -o "$TEMP_FILE" "https://raw.githubusercontent.com/datasciencedojo/datasets/refs/heads/master/titanic.csv"; then
    print_success "Downloaded test data"
    
    # Get file info
    FILE_SIZE=$(wc -c < "$TEMP_FILE")
    LINE_COUNT=$(wc -l < "$TEMP_FILE")
    print_info "File size: $((FILE_SIZE / 1024)) KB, Lines: $LINE_COUNT"
else
    print_error "Failed to download test data"
    exit 1
fi

# Check if bucket exists
BUCKET_NAME="${PROJECT_ID}-temp-bucket"
print_step "Checking temp bucket: gs://$BUCKET_NAME"

if gsutil ls "gs://$BUCKET_NAME" >/dev/null 2>&1; then
    print_success "Temp bucket exists"
else
    print_error "Temp bucket 'gs://$BUCKET_NAME' not found"
    exit 1
fi

# Upload file to trigger function
print_step "Uploading file to trigger Cloud Function..."
UPLOAD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if gsutil cp "$TEMP_FILE" "gs://$BUCKET_NAME/titanic.csv"; then
    print_success "File uploaded successfully"
    print_info "Upload time: $UPLOAD_TIME"
else
    print_error "Failed to upload file"
    exit 1
fi

# Wait for function execution
print_step "Waiting for function execution (30 seconds)..."
sleep 30

# Check for new logs after upload
print_step "Checking for new function execution logs..."
NEW_LOGS=$(gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=\"$UPLOAD_TIME\"" --project="$PROJECT_ID" --limit=10 --format="table(timestamp,severity,textPayload)" 2>/dev/null || echo "")

if [ -n "$NEW_LOGS" ]; then
    print_success "New function execution detected!"
    echo "$NEW_LOGS"
else
    print_warning "No new function execution logs found"
    print_info "Function might still be processing or there might be an issue"
fi

# Test 4: Verify BigQuery table
print_step "Checking BigQuery table creation..."
sleep 10  # Additional wait for BigQuery operations

if bq show --project_id="$PROJECT_ID" "test_dataset.titanic" >/dev/null 2>&1; then
    print_success "BigQuery table 'test_dataset.titanic' exists"
    
    # Get table info
    ROW_COUNT=$(bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --format="csv" --quiet "SELECT COUNT(*) FROM \`$PROJECT_ID.test_dataset.titanic\`" | tail -n 1)
    print_info "Rows in table: $ROW_COUNT"
    
    # Get table size
    TABLE_SIZE=$(bq show --project_id="$PROJECT_ID" --format="value(numBytes)" "test_dataset.titanic")
    if [ -n "$TABLE_SIZE" ] && [ "$TABLE_SIZE" != "0" ]; then
        TABLE_SIZE_KB=$((TABLE_SIZE / 1024))
        print_info "Table size: ${TABLE_SIZE_KB} KB"
    fi
    
    # Show sample data
    print_step "Fetching sample data..."
    SAMPLE_DATA=$(bq query --project_id="$PROJECT_ID" --use_legacy_sql=false --format="table" --max_rows=3 "SELECT * FROM \`$PROJECT_ID.test_dataset.titanic\` LIMIT 3" 2>/dev/null || echo "")
    
    if [ -n "$SAMPLE_DATA" ]; then
        print_success "Sample data:"
        echo "$SAMPLE_DATA"
    fi
    
else
    print_error "BigQuery table 'test_dataset.titanic' not found"
    print_warning "Cloud Function may have failed to load data"
fi

# Cleanup
print_step "Cleaning up..."
rm -f "$TEMP_FILE"
print_success "Local test file cleaned up"

echo ""
print_success "🎉 Quick Cloud Function test completed!"
echo ""
print_info "💡 For detailed monitoring:"
print_info "   gcloud logging read 'resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader' --project=$PROJECT_ID --limit=20"
echo ""
print_info "💡 To test manually:"
print_info "   gsutil cp your_file.csv gs://${PROJECT_ID}-temp-bucket/titanic.csv"
