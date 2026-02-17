#!/bin/bash
# Explore the raw/ folder structure to find data files

set -e

BUCKET="health-data-lake-640768199126-us-east-2"
REGION="us-east-2"
TENANT_ID="${1:-rajasaikatukuri}"

echo "=========================================="
echo "Exploring Raw Data Folder Structure"
echo "=========================================="
echo ""
echo "Bucket: $BUCKET"
echo "Raw folder: s3://$BUCKET/health-data/raw/"
echo ""

# Step 1: List contents of raw/ folder
echo "Step 1: Listing contents of raw/ folder..."
echo ""
aws s3 ls "s3://$BUCKET/health-data/raw/" 2>/dev/null | head -20

echo ""
echo "Step 2: Checking for tenant_id partitions..."
echo ""
aws s3 ls "s3://$BUCKET/health-data/raw/" | grep -i "tenant" | head -10

echo ""
echo "Step 3: Checking for your tenant_id..."
echo ""
TENANT_PATH="s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/"
echo "Checking: $TENANT_PATH"
aws s3 ls "$TENANT_PATH" 2>/dev/null | head -10 || echo "  No tenant_id partition found"

echo ""
echo "Step 4: Finding all Parquet files in raw/..."
echo ""
PARQUET_COUNT=$(aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | grep -i "\.parquet" | wc -l)
echo "Found $PARQUET_COUNT Parquet files"

if [ "$PARQUET_COUNT" -gt 0 ]; then
    echo ""
    echo "Sample Parquet files:"
    aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | grep -i "\.parquet" | head -10
    
    echo ""
    echo "Step 5: Analyzing partition structure..."
    echo ""
    
    # Get first file to analyze structure
    FIRST_FILE=$(aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | grep -i "\.parquet" | head -1 | awk '{print $4}')
    
    if [ -n "$FIRST_FILE" ]; then
        echo "Sample file: $FIRST_FILE"
        echo ""
        
        # Check if it has partition structure
        if [[ "$FIRST_FILE" == *"tenant_id="* ]] && [[ "$FIRST_FILE" == *"dt="* ]]; then
            echo "✅ Detected partition structure: tenant_id=xxx/dt=YYYY-MM-DD/"
            echo ""
            
            # Extract all unique partitions
            echo "Extracting partitions..."
            PARTITIONS=$(aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | \
                grep -oP "tenant_id=[^/]+/dt=[^/]+" | \
                sort -u)
            
            PARTITION_COUNT=$(echo "$PARTITIONS" | wc -l)
            echo "Found $PARTITION_COUNT unique partitions"
            echo ""
            echo "Partitions:"
            echo "$PARTITIONS" | head -20
        else
            echo "⚠️  Files don't appear to be in partition structure"
            echo "   Files might be flat or use different structure"
        fi
    fi
else
    echo ""
    echo "⚠️  No Parquet files found in raw/ folder"
    echo ""
    echo "Checking for other file types..."
    aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | head -20
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "Raw folder location: s3://$BUCKET/health-data/raw/"
echo "This matches the expected table location!"
echo ""
echo "Next steps:"
echo "1. If partitions found, add them to Athena"
echo "2. Test data access"
echo "3. Refresh gold tables"
echo ""



