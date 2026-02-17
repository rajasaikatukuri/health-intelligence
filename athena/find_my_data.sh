#!/bin/bash
# Find where your data actually is in S3

set -e

BUCKET="health-data-lake-640768199126-us-east-2"
REGION="us-east-2"

echo "=========================================="
echo "Finding Your Data in S3"
echo "=========================================="
echo ""
echo "Bucket: $BUCKET"
echo "Region: $REGION"
echo ""

# List top-level directories
echo "Step 1: Listing top-level directories..."
echo ""
aws s3 ls "s3://$BUCKET/" 2>/dev/null | head -20

echo ""
echo "Step 2: Searching for Parquet files..."
echo ""

# Find all .parquet files
PARQUET_FILES=$(aws s3 ls "s3://$BUCKET/" --recursive 2>/dev/null | grep -i "\.parquet" | head -20)

if [ -n "$PARQUET_FILES" ]; then
    echo "✅ Found Parquet files:"
    echo "$PARQUET_FILES" | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    # Extract common prefix
    FIRST_FILE=$(echo "$PARQUET_FILES" | head -1 | awk '{print $4}')
    echo "Sample file path: $FIRST_FILE"
    echo ""
    
    # Try to extract partition structure
    if [[ "$FIRST_FILE" == *"tenant_id"* ]] && [[ "$FIRST_FILE" == *"dt="* ]]; then
        echo "✅ Detected partition structure: tenant_id=xxx/dt=YYYY-MM-DD/"
        echo ""
        echo "Extracting base path..."
        BASE_PATH=$(echo "$FIRST_FILE" | sed 's|/tenant_id=.*||')
        echo "Base path: s3://$BUCKET/$BASE_PATH"
    fi
else
    echo "❌ No .parquet files found"
    echo ""
fi

echo ""
echo "Step 3: Searching for any data files..."
echo ""

# Find any files (not just parquet)
ALL_FILES=$(aws s3 ls "s3://$BUCKET/" --recursive 2>/dev/null | head -30)

if [ -n "$ALL_FILES" ]; then
    echo "Found files in bucket:"
    echo "$ALL_FILES" | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    # Count files
    FILE_COUNT=$(aws s3 ls "s3://$BUCKET/" --recursive 2>/dev/null | wc -l)
    echo "Total files: $FILE_COUNT"
else
    echo "❌ No files found in bucket"
    echo ""
    echo "Possible issues:"
    echo "1. Bucket name is incorrect"
    echo "2. AWS credentials don't have access"
    echo "3. Data is in a different bucket"
    echo ""
    echo "To list all your buckets:"
    echo "  aws s3 ls"
fi

echo ""
echo "Step 4: Checking for common data patterns..."
echo ""

# Check for common patterns
PATTERNS=(
    "tenant"
    "health"
    "data"
    "raw"
    "parquet"
    "json"
)

for pattern in "${PATTERNS[@]}"; do
    MATCHES=$(aws s3 ls "s3://$BUCKET/" --recursive 2>/dev/null | grep -i "$pattern" | head -5)
    if [ -n "$MATCHES" ]; then
        echo "Files matching '$pattern':"
        echo "$MATCHES" | while read -r line; do
            echo "  $line"
        done
        echo ""
    fi
done

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "If you found your data:"
echo "1. Note the S3 path structure"
echo "2. Update the table location if needed:"
echo "   ALTER TABLE health_data_lake.health_data_raw SET LOCATION 's3://$BUCKET/YOUR_PATH/';"
echo ""
echo "3. Add partitions if using partitioned structure"
echo "4. Refresh gold tables"
echo ""



