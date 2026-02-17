#!/bin/bash
# Connect existing S3 data to Athena tables

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="${1:-rajasaikatukuri}"

echo "=========================================="
echo "Connecting Existing S3 Data to Athena"
echo "=========================================="
echo ""
echo "Tenant ID: $TENANT_ID"
echo "Bucket: $BUCKET"
echo "Region: $REGION"
echo ""

# Step 1: Check what data exists in S3
echo "Step 1: Checking S3 for existing data..."
echo ""

# Check different possible paths
PATHS_TO_CHECK=(
    "s3://$BUCKET/health-data/raw/"
    "s3://$BUCKET/raw/"
    "s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/"
    "s3://$BUCKET/data/"
)

FOUND_PATH=""
for path in "${PATHS_TO_CHECK[@]}"; do
    echo "Checking: $path"
    COUNT=$(aws s3 ls "$path" --recursive 2>/dev/null | wc -l || echo "0")
    if [ "$COUNT" -gt 0 ]; then
        echo "  ✅ Found $COUNT objects"
        FOUND_PATH="$path"
        
        # Show sample files
        echo "  Sample files:"
        aws s3 ls "$path" --recursive | head -5 | while read -r line; do
            echo "    $line"
        done
        break
    else
        echo "  ❌ No data found"
    fi
    echo ""
done

if [ -z "$FOUND_PATH" ]; then
    echo "❌ No data found in any expected location!"
    echo ""
    echo "Please check:"
    echo "1. Bucket name is correct: $BUCKET"
    echo "2. Data exists in S3"
    echo "3. AWS credentials are configured"
    echo ""
    echo "To list all files in bucket:"
    echo "  aws s3 ls s3://$BUCKET/ --recursive | head -20"
    exit 1
fi

echo ""
echo "✅ Found data at: $FOUND_PATH"
echo ""

# Step 2: Update table location if needed
echo "Step 2: Verifying table location matches S3 path..."
echo ""

# Extract the S3 prefix (remove s3://bucket/)
S3_PREFIX=$(echo "$FOUND_PATH" | sed "s|s3://$BUCKET/||")

# Check current table location
CURRENT_LOCATION=$(aws athena get-table-metadata \
    --catalog-name AwsDataCatalog \
    --database-name "$DATABASE" \
    --table-name health_data_raw \
    --region "$REGION" \
    2>/dev/null | jq -r '.TableMetadata.Parameters.location' || echo "")

if [ -n "$CURRENT_LOCATION" ]; then
    echo "Current table location: $CURRENT_LOCATION"
    EXPECTED_LOCATION="s3://$BUCKET/$S3_PREFIX"
    
    if [ "$CURRENT_LOCATION" != "$EXPECTED_LOCATION" ]; then
        echo "⚠️  Location mismatch!"
        echo "   Expected: $EXPECTED_LOCATION"
        echo "   Current:  $CURRENT_LOCATION"
        echo ""
        echo "Updating table location..."
        
        UPDATE_QUERY="ALTER TABLE $DATABASE.health_data_raw SET LOCATION 's3://$BUCKET/$S3_PREFIX'"
        
        QUERY_ID=$(aws athena start-query-execution \
            --query-string "$UPDATE_QUERY" \
            --work-group "$WORKGROUP" \
            --region "$REGION" \
            --query 'QueryExecutionId' \
            --output text)
        
        echo "Query ID: $QUERY_ID"
        echo "Waiting for completion..."
        
        aws athena wait query-execution-completed \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" 2>/dev/null || true
        
        STATUS=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.State' \
            --output text)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "✅ Table location updated"
        else
            echo "⚠️  Update may have failed, but continuing..."
        fi
    else
        echo "✅ Table location is correct"
    fi
else
    echo "⚠️  Could not read table metadata, but continuing..."
fi

# Step 3: Discover and add partitions
echo ""
echo "Step 3: Discovering partitions..."
echo ""

# Find all unique tenant_id/dt combinations
echo "Scanning S3 for partition structure..."

# Try to find partitions
PARTITIONS=$(aws s3 ls "s3://$BUCKET/$S3_PREFIX" --recursive 2>/dev/null | \
    grep -oP "tenant_id=[^/]+/dt=[^/]+" | \
    sort -u | head -20 || echo "")

if [ -z "$PARTITIONS" ]; then
    echo "⚠️  Could not auto-detect partition structure"
    echo ""
    echo "Please manually add partitions. Example:"
    echo ""
    echo "ALTER TABLE $DATABASE.health_data_raw ADD PARTITION (tenant_id='$TENANT_ID', dt='2024-01-15');"
    echo ""
    echo "Or use MSCK REPAIR TABLE (if supported):"
    echo "MSCK REPAIR TABLE $DATABASE.health_data_raw;"
else
    echo "Found partitions:"
    echo "$PARTITIONS" | while read -r partition; do
        echo "  - $partition"
    done
    
    echo ""
    echo "Adding partitions..."
    
    # Extract tenant_id and dt from partition string
    echo "$PARTITIONS" | while read -r partition; do
        TENANT=$(echo "$partition" | grep -oP "tenant_id=\K[^/]+")
        DT=$(echo "$partition" | grep -oP "dt=\K[^/]+")
        
        if [ -n "$TENANT" ] && [ -n "$DT" ]; then
            ADD_PARTITION_QUERY="ALTER TABLE $DATABASE.health_data_raw ADD IF NOT EXISTS PARTITION (tenant_id='$TENANT', dt='$DT')"
            
            QUERY_ID=$(aws athena start-query-execution \
                --query-string "$ADD_PARTITION_QUERY" \
                --work-group "$WORKGROUP" \
                --region "$REGION" \
                --query 'QueryExecutionId' \
                --output text 2>/dev/null || echo "")
            
            if [ -n "$QUERY_ID" ]; then
                echo "  Adding partition: tenant_id=$TENANT, dt=$DT"
                # Don't wait, just fire and forget for speed
            fi
        fi
    done
    
    echo ""
    echo "✅ Partitions added (may take a moment to complete)"
fi

# Step 4: Test query
echo ""
echo "Step 4: Testing data access..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
LIMIT 1"

echo "Running test query..."
QUERY_ID=$(aws athena start-query-execution \
    --query-string "$TEST_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting for results (this may take 30-60 seconds)..."

MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Query succeeded!"
        
        # Get results
        RESULTS=$(aws athena get-query-results \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text 2>/dev/null || echo "0")
        
        echo ""
        echo "📊 Row count: $RESULTS"
        
        if [ "$RESULTS" != "0" ] && [ -n "$RESULTS" ]; then
            echo ""
            echo "✅ Data is accessible!"
        else
            echo ""
            echo "⚠️  Query returned 0 rows. This could mean:"
            echo "   - Partitions need to be added manually"
            echo "   - Data format doesn't match expected schema"
            echo "   - tenant_id filter doesn't match your data"
        fi
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        echo "❌ Query failed: $REASON"
        break
    fi
    
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    if [ $((ELAPSED % 10)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s)"
    fi
done

# Step 5: Refresh gold tables
echo ""
echo "=========================================="
echo "Step 5: Next Steps"
echo "=========================================="
echo ""
echo "If data is accessible, refresh gold tables:"
echo ""
echo "  cd $(dirname "$0")"
echo "  ./create_gold_tables_for_tenant.sh $TENANT_ID"
echo ""
echo "Then try your queries in the chat interface!"
echo ""



