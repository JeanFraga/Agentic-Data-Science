#!/bin/bash

# Cloud Function Diagnostic Script
# Usage: ./diagnose_cloud_function.sh <project_id>

set -e

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID is required as first argument"
    echo "Usage: $0 <project_id>"
    exit 1
fi

echo "🔍 Cloud Function Diagnostic Report"
echo "Project: $PROJECT_ID"
echo "Date: $(date)"
echo "======================================="
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

# 1. Check if Cloud Function exists
print_step "1. Checking Cloud Function deployment status..."
if gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --quiet >/dev/null 2>&1; then
    print_success "Cloud Function 'titanic-data-loader' exists"
    
    # Get detailed function info
    echo ""
    print_info "Function Details:"
    gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="table(name,status,runtime,timeout,availableMemoryMb,serviceAccountEmail,eventTrigger.eventType,eventTrigger.resource)"
    
    # Check function status
    FUNCTION_STATUS=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(status)")
    if [ "$FUNCTION_STATUS" = "ACTIVE" ]; then
        print_success "Function status: ACTIVE"
    else
        print_error "Function status: $FUNCTION_STATUS (Expected: ACTIVE)"
    fi
    
else
    print_error "Cloud Function 'titanic-data-loader' NOT FOUND"
    echo ""
    print_info "Available functions in project:"
    gcloud functions list --project="$PROJECT_ID" --format="table(name,status,trigger.eventTrigger.eventType)"
    echo ""
    print_warning "This indicates the Terraform deployment may have failed or the function wasn't created"
    exit 1
fi

echo ""

# 2. Check service account
print_step "2. Checking Cloud Function service account..."
FUNCTION_SA=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(serviceAccountEmail)")
if [ -n "$FUNCTION_SA" ]; then
    print_success "Service Account: $FUNCTION_SA"
    
    # Check if service account exists
    if gcloud iam service-accounts describe "$FUNCTION_SA" --project="$PROJECT_ID" >/dev/null 2>&1; then
        print_success "Service account exists and is accessible"
    else
        print_error "Service account $FUNCTION_SA does not exist or is not accessible"
    fi
else
    print_warning "No service account configured (using default)"
fi

echo ""

# 3. Check trigger configuration
print_step "3. Checking trigger configuration..."
TRIGGER_BUCKET=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(eventTrigger.resource)")
TRIGGER_EVENT=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(eventTrigger.eventType)")

if [ -n "$TRIGGER_BUCKET" ]; then
    print_success "Trigger configured: $TRIGGER_EVENT on $TRIGGER_BUCKET"
    
    # Check if trigger bucket exists
    if gsutil ls "$TRIGGER_BUCKET" >/dev/null 2>&1; then
        print_success "Trigger bucket exists and is accessible"
        
        # Check bucket contents
        BUCKET_CONTENTS=$(gsutil ls "$TRIGGER_BUCKET/**" 2>/dev/null || echo "")
        if [ -n "$BUCKET_CONTENTS" ]; then
            print_info "Bucket contents:"
            echo "$BUCKET_CONTENTS"
        else
            print_info "Bucket is empty"
        fi
    else
        print_error "Trigger bucket $TRIGGER_BUCKET does not exist or is not accessible"
    fi
else
    print_error "No trigger configuration found"
fi

echo ""

# 4. Check function source code
print_step "4. Checking function source code..."
SOURCE_BUCKET=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(sourceArchiveUrl)" | cut -d'/' -f3)
SOURCE_OBJECT=$(gcloud functions describe titanic-data-loader --region=us-central1 --project="$PROJECT_ID" --format="value(sourceArchiveUrl)" | cut -d'/' -f4-)

if [ -n "$SOURCE_BUCKET" ] && [ -n "$SOURCE_OBJECT" ]; then
    print_success "Source code: gs://$SOURCE_BUCKET/$SOURCE_OBJECT"
    
    if gsutil ls "gs://$SOURCE_BUCKET/$SOURCE_OBJECT" >/dev/null 2>&1; then
        print_success "Source code file exists"
        
        # Get source file info
        SOURCE_SIZE=$(gsutil ls -l "gs://$SOURCE_BUCKET/$SOURCE_OBJECT" | awk '{print $1}' | tail -n 1)
        print_info "Source code size: $SOURCE_SIZE bytes"
    else
        print_error "Source code file does not exist"
    fi
else
    print_warning "Could not determine source code location"
fi

echo ""

# 5. Check required APIs
print_step "5. Checking required APIs..."
REQUIRED_APIS=(
    "cloudfunctions.googleapis.com"
    "cloudbuild.googleapis.com"
    "eventarc.googleapis.com"
    "bigquery.googleapis.com"
    "storage.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" --project="$PROJECT_ID" >/dev/null 2>&1; then
        print_success "API enabled: $api"
    else
        print_error "API NOT enabled: $api"
    fi
done

echo ""

# 6. Check function logs
print_step "6. Checking function execution logs..."
print_info "Searching for logs from the last 24 hours..."

LOGS=$(gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader" --project="$PROJECT_ID" --limit=10 --format="table(timestamp,severity,textPayload)" 2>/dev/null || echo "")

if [ -n "$LOGS" ]; then
    print_success "Found recent logs:"
    echo "$LOGS"
else
    print_warning "No logs found in the last 24 hours"
    print_info "This could mean:"
    echo "  - Function has never been triggered"
    echo "  - Function deployment failed"
    echo "  - Logs are not being generated properly"
fi

echo ""

# 7. Check IAM permissions
print_step "7. Checking IAM permissions..."
if [ -n "$FUNCTION_SA" ]; then
    print_info "Checking permissions for service account: $FUNCTION_SA"
    
    # Check BigQuery permissions
    if gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:$FUNCTION_SA AND bindings.role:roles/bigquery.dataEditor" --format="value(bindings.role)" | grep -q "bigquery.dataEditor"; then
        print_success "Has BigQuery dataEditor permission"
    else
        print_error "Missing BigQuery dataEditor permission"
    fi
    
    # Check Storage permissions
    if gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:$FUNCTION_SA AND bindings.role:roles/storage.objectViewer" --format="value(bindings.role)" | grep -q "storage.objectViewer"; then
        print_success "Has Storage objectViewer permission"
    else
        print_error "Missing Storage objectViewer permission"
    fi
else
    print_info "Using default service account - checking default permissions..."
fi

echo ""

# 8. Test trigger manually
print_step "8. Testing function trigger manually..."
TEMP_BUCKET="$PROJECT_ID-temp-bucket"

print_info "Creating test file..."
cat > test_trigger.csv << EOF
PassengerId,Survived,Pclass,Name,Sex,Age
1,0,3,"Test Passenger",male,22
EOF

print_info "Uploading test file to trigger bucket..."
if gsutil cp test_trigger.csv "gs://$TEMP_BUCKET/titanic.csv"; then
    print_success "Test file uploaded successfully"
    
    print_info "Waiting 15 seconds for function execution..."
    sleep 15
    
    # Check for new logs
    NEW_LOGS=$(gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=\"$(date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%SZ)\"" --project="$PROJECT_ID" --limit=5 --format="table(timestamp,severity,textPayload)" 2>/dev/null || echo "")
    
    if [ -n "$NEW_LOGS" ]; then
        print_success "Function execution detected after test upload!"
        echo "$NEW_LOGS"
    else
        print_error "No function execution detected after test upload"
        print_warning "This indicates the trigger is not working properly"
    fi
    
    # Clean up test file
    rm -f test_trigger.csv
    print_info "Test file cleaned up"
else
    print_error "Failed to upload test file"
fi

echo ""

# 9. Summary and recommendations
print_step "9. Diagnostic Summary"
echo ""
print_info "DIAGNOSIS COMPLETE"
echo ""

# Provide recommendations based on findings
if [ "$FUNCTION_STATUS" != "ACTIVE" ]; then
    print_error "CRITICAL: Function is not in ACTIVE state"
    echo "Recommendation: Redeploy the function using Terraform"
fi

if [ -z "$TRIGGER_BUCKET" ]; then
    print_error "CRITICAL: No trigger configured"
    echo "Recommendation: Check Terraform configuration for event trigger"
fi

if [ -z "$LOGS" ]; then
    print_warning "WARNING: No execution logs found"
    echo "Recommendation: Function may never have been triggered or has permission issues"
fi

echo ""
print_info "💡 Next steps to fix the Cloud Function:"
echo "1. Check Terraform apply logs for any deployment errors"
echo "2. Verify all required APIs are enabled"
echo "3. Check IAM permissions for the function service account"
echo "4. Try redeploying the function with: terraform apply -target=google_cloudfunctions_function.titanic_data_loader"
echo "5. Monitor logs in real-time: gcloud logging tail 'resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader' --project=$PROJECT_ID"

echo ""
print_info "🔧 Useful debugging commands:"
echo "# Check function deployment"
echo "gcloud functions describe titanic-data-loader --region=us-central1 --project=$PROJECT_ID"
echo ""
echo "# Monitor real-time logs"
echo "gcloud logging tail 'resource.type=cloud_function' --project=$PROJECT_ID"
echo ""
echo "# Test manual trigger"
echo "gsutil cp your_file.csv gs://$PROJECT_ID-temp-bucket/titanic.csv"
