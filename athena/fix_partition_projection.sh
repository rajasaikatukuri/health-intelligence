#!/bin/bash
# Fix partition projection or switch to regular partitions

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"

echo "=========================================="
echo "Fixing Partition Configuration"
echo "=========================================="
echo ""
echo "The table uses partition projection which requires WHERE tenant_id filters."
echo "But queries are returning 0 rows. Let's check and fix."
echo ""

# Step 1: Check current table properties
echo "Step 1: Checking current table properties..."
echo ""

SHOW_TABLE_QUERY="SHOW CREATE TABLE $DATABASE.health_data_raw"

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$SHOW_TABLE_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting..."

sleep 10
STATUS=$(aws athena get-query-execution \
    --query-execution-id "$QUERY_ID" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS" = "SUCCEEDED" ]; then
    echo "✅ Got table definition"
    echo ""
    echo "Table DDL:"
    aws athena get-query-results \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'ResultSet.Rows[*].Data[*].VarCharValue' \
        --output text 2>/dev/null | head -30
    echo ""
else
    echo "⚠️  Could not get table definition, proceeding with fix..."
    echo ""
fi

# Step 2: Drop and recreate table WITHOUT partition projection
echo "Step 2: Recreating table WITHOUT partition projection..."
echo ""
echo "This will use regular partitions instead of partition projection."
echo ""

DROP_TABLE_QUERY="DROP TABLE IF EXISTS $DATABASE.health_data_raw"

echo "Dropping old table..."
DROP_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$DROP_TABLE_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

sleep 5

# Create new table without partition projection
CREATE_TABLE_DDL=$(cat <<EOF
CREATE EXTERNAL TABLE $DATABASE.health_data_raw (
    data_type string,
    value double,
    timestamp string,
    timestamp_unix bigint,
    unit string,
    source_name string,
    source_version string,
    device string,
    metadata string
)
PARTITIONED BY (
    tenant_id string,
    dt string
)
STORED AS PARQUET
LOCATION 's3://$BUCKET/health-data/raw/'
TBLPROPERTIES (
    'projection.enabled' = 'false'
)
EOF
)

echo "Creating new table (no partition projection)..."
CREATE_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$CREATE_TABLE_DDL" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $CREATE_QUERY_ID"
echo "Waiting for table creation..."

MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$CREATE_QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Table created successfully"
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$CREATE_QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        echo "❌ Failed: $REASON"
        exit 1
    fi
    
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# Step 3: Add partition
echo ""
echo "Step 3: Adding partition for your data..."
echo ""

ADD_PARTITION_QUERY="ALTER TABLE $DATABASE.health_data_raw ADD IF NOT EXISTS PARTITION (tenant_id='$TENANT_ID', dt='2026-01-04')"

PART_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$ADD_PARTITION_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $PART_QUERY_ID"
echo "Waiting..."

sleep 5
PART_STATUS=$(aws athena get-query-execution \
    --query-execution-id "$PART_QUERY_ID" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$PART_STATUS" = "SUCCEEDED" ]; then
    echo "✅ Partition added"
else
    REASON=$(aws athena get-query-execution \
        --query-execution-id "$PART_QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.StateChangeReason' \
        --output text 2>/dev/null || echo "Unknown")
    echo "⚠️  Partition addition: $PART_STATUS - $REASON"
fi

# Step 4: Test query
echo ""
echo "Step 4: Testing data access..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
  AND dt = '2026-01-04'
LIMIT 1"

TEST_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$TEST_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
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
            echo "   Run: ./setup_tables_simple.sh (Step 2 will recreate the view)"
            echo ""
            echo "2. Refresh gold tables:"
            echo "   ./create_gold_tables_for_tenant.sh $TENANT_ID"
            echo ""
            echo "3. Try your queries in the chat interface! 🎉"
        else
            echo "⚠️  Still returning 0 rows"
            echo ""
            echo "The Parquet files might be empty or have a schema issue."
            echo "Run this to check the actual file schema:"
            echo "  cd ../backend"
            echo "  source venv/bin/activate"
            echo "  python3 ../athena/check_parquet_schema.py"
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
        break
    fi
    
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s)"
    fi
done

echo ""



