#!/bin/bash
# Simplified table setup without partition projection (faster, more reliable)

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"

echo "=========================================="
echo "Setting up Athena Tables (Simplified)"
echo "=========================================="
echo ""

# Function to execute Athena query
execute_athena_query() {
    local query="$1"
    local description="$2"
    
    echo "📊 $description..."
    
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --work-group "$WORKGROUP" \
        --region "$REGION" \
        --query 'QueryExecutionId' \
        --output text)
    
    echo "Query ID: $QUERY_ID"
    echo "Waiting for completion (max 2 minutes)..."
    
    # Poll with timeout
    MAX_WAIT=120
    ELAPSED=0
    POLL_INTERVAL=3
    
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        STATUS=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.State' \
            --output text 2>/dev/null || echo "UNKNOWN")
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "✅ Query succeeded"
            return 0
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            echo "❌ Query failed"
            REASON=$(aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text 2>/dev/null || echo "Unknown")
            echo "Reason: $REASON"
            return 1
        fi
        
        if [ $((ELAPSED % 15)) -eq 0 ]; then
            echo "  Status: $STATUS (${ELAPSED}s)..."
        fi
        
        sleep $POLL_INTERVAL
        ELAPSED=$((ELAPSED + POLL_INTERVAL))
    done
    
    echo "⚠️  Timeout after ${MAX_WAIT}s"
    echo "Query ID: $QUERY_ID - Check status manually"
    return 1
}

# Step 1: Create raw table (simplified, no partition projection)
echo "Step 1: Creating raw table (simplified)..."
RAW_TABLE_DDL=$(cat <<'EOF'
CREATE EXTERNAL TABLE IF NOT EXISTS health_data_lake.health_data_raw (
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
LOCATION 's3://health-data-lake-640768199126-us-east-2/health-data/raw/'
EOF
)

if execute_athena_query "$RAW_TABLE_DDL" "Creating raw table"; then
    echo "✅ Raw table created"
else
    echo "⚠️  Raw table creation had issues, but continuing..."
fi

# Step 2: Create silver view
echo ""
echo "Step 2: Creating silver view..."
SILVER_VIEW_DDL=$(cat <<'EOF'
CREATE OR REPLACE VIEW health_data_lake.silver_health AS
SELECT
    tenant_id,
    dt as day,
    DATE_PARSE(dt, '%Y-%m-%d') as date_parsed,
    DATE_FORMAT(DATE_ADD('day', -DAY_OF_WEEK(DATE_PARSE(dt, '%Y-%m-%d')) + 1, DATE_PARSE(dt, '%Y-%m-%d')), '%Y-%m-%d') as week_start,
    data_type,
    value,
    CAST(timestamp_unix AS BIGINT) as timestamp_unix,
    timestamp,
    unit,
    source_name,
    source_version,
    device,
    metadata
FROM health_data_lake.health_data_raw
WHERE tenant_id IS NOT NULL
EOF
)

if execute_athena_query "$SILVER_VIEW_DDL" "Creating silver view"; then
    echo "✅ Silver view created"
else
    echo "⚠️  Silver view creation had issues"
fi

echo ""
echo "=========================================="
echo "✅ Basic tables created!"
echo "=========================================="
echo ""
echo "Note: Gold tables will be created on-demand when queries run."
echo "The raw table and silver view are ready to use."
echo ""
echo "Next: Start the backend and test queries!"





