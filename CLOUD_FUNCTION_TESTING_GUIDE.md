# Cloud Function Testing Guide

This guide provides comprehensive instructions for testing your Cloud Function that automatically loads Titanic data to BigQuery.

## 🧪 Available Testing Scripts

### 1. **Comprehensive Test Suite** (PowerShell)
```powershell
.\scripts\test_cloud_function.ps1 -ProjectId "your-project-id" -TestMode "full"
```

**Test Modes:**
- `full` - Complete testing including performance tests
- `quick` - Basic functionality test (recommended for regular use)
- `logs-only` - Only check function logs
- `function-status` - Only verify function deployment

### 2. **Quick Bash Test**
```bash
./scripts/test_cloud_function_quick.sh your-project-id
```

### 3. **Enhanced Data Loading with Function Testing**
```bash
./scripts/check_and_load_titanic_data.sh your-project-id
```

### 4. **Live Monitoring**
```powershell
.\scripts\monitor_cloud_function.ps1 -ProjectId "your-project-id" -MonitorDuration 5
```

## 🔍 Manual Testing Steps

### Step 1: Verify Function Deployment
```bash
gcloud functions describe titanic-data-loader \
  --region=us-central1 \
  --project=your-project-id
```

**Expected Output:**
- Status: `ACTIVE`
- Runtime: `python311`
- Trigger: Storage bucket event
- Entry point: `load_titanic_to_bigquery`

### Step 2: Check Function Logs
```bash
gcloud logging read \
  "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader" \
  --project=your-project-id \
  --limit=10
```

### Step 3: Test File Upload Trigger
```bash
# Download test data
curl -o titanic.csv "https://raw.githubusercontent.com/datasciencedojo/datasets/refs/heads/master/titanic.csv"

# Upload to trigger function
gsutil cp titanic.csv gs://your-project-id-temp-bucket/titanic.csv
```

### Step 4: Monitor Function Execution
```bash
# Watch logs in real-time
gcloud logging tail \
  "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader" \
  --project=your-project-id
```

### Step 5: Verify BigQuery Data Loading
```bash
# Check if table exists
bq show --project_id=your-project-id test_dataset.titanic

# Get row count
bq query --project_id=your-project-id \
  --use_legacy_sql=false \
  "SELECT COUNT(*) as total_rows FROM \`your-project-id.test_dataset.titanic\`"

# Sample data
bq query --project_id=your-project-id \
  --use_legacy_sql=false \
  "SELECT * FROM \`your-project-id.test_dataset.titanic\` LIMIT 5"
```

## 🎯 What to Look For

### ✅ Success Indicators
1. **Function Status**: `ACTIVE` in function description
2. **Trigger Configuration**: Event trigger on correct bucket
3. **Log Messages**: 
   - "Processing file: titanic.csv"
   - "Successfully loaded X rows into..."
   - No ERROR severity logs
4. **BigQuery Table**: 
   - Table exists in `test_dataset.titanic`
   - Contains ~891 rows (Titanic dataset size)
   - Data sample shows passenger information

### ❌ Common Issues

#### Function Not Triggering
**Symptoms:** No logs after file upload
**Causes:**
- Function not deployed
- Incorrect bucket trigger configuration
- Permissions issues

**Debug:**
```bash
# Check function exists
gcloud functions list --project=your-project-id

# Verify trigger bucket
gcloud functions describe titanic-data-loader --region=us-central1 --project=your-project-id --format="value(eventTrigger.resource)"

# Check bucket permissions
gsutil iam get gs://your-project-id-temp-bucket
```

#### Function Failing
**Symptoms:** ERROR logs in function execution
**Common Errors:**
- BigQuery permission denied
- Dataset doesn't exist
- Python package import errors

**Debug:**
```bash
# Check detailed error logs
gcloud logging read \
  "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND severity=ERROR" \
  --project=your-project-id \
  --limit=5
```

#### BigQuery Not Updating
**Symptoms:** Function executes but table not created/updated
**Causes:**
- BigQuery API not enabled
- Service account lacks BigQuery permissions
- Dataset doesn't exist

**Debug:**
```bash
# Check if dataset exists
bq ls --project_id=your-project-id

# Create dataset if missing
bq mk --project_id=your-project-id --description="Test dataset" test_dataset

# Check service account permissions
gcloud projects get-iam-policy your-project-id
```

## 🔧 Troubleshooting Commands

### Check Function Metrics
```bash
gcloud functions describe titanic-data-loader \
  --region=us-central1 \
  --project=your-project-id \
  --format="table(status,updateTime,versionId,runtime)"
```

### View Recent Function Activity
```bash
gcloud logging read \
  "resource.type=cloud_function AND resource.labels.function_name=titanic-data-loader AND timestamp>=2024-01-01" \
  --project=your-project-id \
  --format="table(timestamp,severity,textPayload)" \
  --limit=20
```

### Test Different File Types
```bash
# Test with different CSV files
echo "name,age,city" > test.csv
echo "John,30,NYC" >> test.csv
gsutil cp test.csv gs://your-project-id-temp-bucket/titanic.csv
```

### Check Bucket Activity
```bash
# List bucket contents
gsutil ls -l gs://your-project-id-temp-bucket/

# Check bucket notifications
gsutil notification list gs://your-project-id-temp-bucket/
```

## 📊 Performance Expectations

### Normal Function Performance
- **Cold Start**: 3-10 seconds for first execution
- **Warm Start**: 1-3 seconds for subsequent executions
- **Data Processing**: ~5-15 seconds for Titanic dataset (891 rows)
- **Total Time**: Usually completes within 30 seconds

### Memory and Timeout
- **Allocated Memory**: 256MB
- **Timeout**: 300 seconds (5 minutes)
- **Expected Usage**: <50MB for Titanic dataset

## 🔄 Automated Testing Integration

### GitHub Actions Testing
```yaml
- name: Test Cloud Function
  run: |
    ./scripts/test_cloud_function_quick.sh ${{ secrets.GCP_PROJECT_ID }}
```

### Scheduled Health Checks
```bash
# Add to crontab for hourly checks
0 * * * * /path/to/test_cloud_function_quick.sh your-project-id >> /var/log/cf-health.log 2>&1
```

## 📝 Test Results Interpretation

### Sample Successful Test Output
```
✅ Cloud Function 'titanic-data-loader' is deployed
ℹ️  Status: ACTIVE
✅ File uploaded successfully
✅ New function execution detected!
✅ BigQuery table 'test_dataset.titanic' exists
ℹ️  Rows in table: 891
🎉 Quick Cloud Function test completed!
```

### Error Patterns to Watch
```
❌ Cloud Function 'titanic-data-loader' not found
⚠️  No new function execution logs found
❌ BigQuery table 'test_dataset.titanic' not found
```

This comprehensive testing approach ensures your Cloud Function is working correctly and provides detailed diagnostics when issues occur.
