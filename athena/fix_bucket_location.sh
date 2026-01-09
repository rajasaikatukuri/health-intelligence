#!/bin/bash
# Fix table location to use correct bucket

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
CORRECT_BUCKET="health-data-lake-640768199126-us-east-2"

echo "=========================================="
echo "Fixing Table Location"
echo "=========================================="
echo ""
echo "The table location might be pointing to the wrong bucket."
echo "Updating to: s3://$CORRECT_BUCKET/health-data/raw/"
echo ""

# Step 1: Update table location
echo "Step 1: Updating table location..."
echo ""

UPDATE_LOCATION_QUERY="ALTER TABLE $DATABASE.health_data_raw SET LOCATION 's3://$CORRECT_BUCKET/health-data/raw/'"

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$UPDATE_LOCATION_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$CORRECT_BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting for completion..."

MAX_WAIT=30
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Location updated successfully"
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        echo "❌ Failed: $REASON"
        echo ""
        echo "Trying alternative: Recreate table with correct location..."
        break
    fi
    
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# Step 2: Re-add partition (in case it was lost)
echo ""
echo "Step 2: Re-adding partition..."
echo ""

ADD_PARTITION_QUERY="ALTER TABLE $DATABASE.health_data_raw ADD IF NOT EXISTS PARTITION (tenant_id='rajasaikatukuri', dt='2026-01-04')"

PART_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$ADD_PARTITION_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$CORRECT_BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $PART_QUERY_ID"
sleep 5

PART_STATUS=$(aws athena get-query-execution \
    --query-execution-id "$PART_QUERY_ID" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$PART_STATUS" = "SUCCEEDED" ]; then
    echo "✅ Partition added"
else
    echo "⚠️  Partition status: $PART_STATUS"
fi

# Step 3: Test query
echo ""
echo "Step 3: Testing data access..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = 'rajasaikatukuri' 
  AND dt = '2026-01-04'
LIMIT 1"

TEST_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$TEST_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$CORRECT_BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $TEST_QUERY_ID"
echo "Waiting for results..."

MAX_WAIT=90
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$TEST_QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        RESULT=$(aws athena get-query-results \
            --query-execution-id "$TEST_QUERY_ID" \
            --region "$REGION" \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text 2>/dev/null || echo "0")
        
        echo ""
        echo "✅ Query succeeded!"
        echo "📊 Row count: $RESULT"
        echo ""
        
        if [ "$RESULT" != "0" ] && [ -n "$RESULT" ] && [ "$RESULT" != "None" ]; then
            echo "✅✅✅ SUCCESS! Data is now accessible! ✅✅✅"
            echo ""
            echo "Next steps:"
            echo "1. Recreate silver view:"
            echo "   ./setup_tables_simple.sh"
            echo ""
            echo "2. Refresh gold tables:"
            echo "   ./create_gold_tables_for_tenant.sh rajasaikatukuri"
            echo ""
            echo "3. Try your queries in the chat interface! 🎉"
        else
            echo "⚠️  Still returning 0 rows"
            echo ""
            echo "Possible issues:"
            echo "1. Files might be empty"
            echo "2. Schema mismatch"
            echo "3. Need to check Parquet file contents"
        fi
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$TEST_QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        echo ""
        echo "❌ Query failed: $REASON"
        echo ""
        
        if [[ "$REASON" == *"Access Denied"* ]] || [[ "$REASON" == *"403"* ]]; then
            echo "⚠️  Permission issue detected!"
            echo ""
            echo "The Athena service role needs permission to read from S3."
            echo "Check:"
            echo "1. Athena workgroup service role has S3 read permissions"
            echo "2. Bucket policy allows Athena to access"
            echo "3. IAM role has s3:GetObject and s3:ListBucket permissions"
            echo ""
            echo "Or the bucket name might be wrong. Check which bucket has your data:"
            echo "  aws s3 ls s3://health-data-lake-640768199126-us-east-2/health-data/raw/tenant_id=rajasaikatukuri/"
        fi
        break
    fi
    
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s)"
    fi
done

echo ""


