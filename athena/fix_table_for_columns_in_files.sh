#!/bin/bash
# Fix table when Parquet files contain tenant_id and dt as columns

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"

echo "=========================================="
echo "Fixing Table for Columns in Parquet Files"
echo "=========================================="
echo ""
echo "Your Parquet files contain tenant_id and dt as columns."
echo "We'll create a view that uses partition values instead."
echo ""

# Step 1: Create a fixed view that uses partition values
echo "Step 1: Creating fixed silver view..."
echo ""

SILVER_VIEW_DDL=$(cat <<'EOF'
CREATE OR REPLACE VIEW health_data_lake.silver_health AS
SELECT
    tenant_id as tenant_id,  -- Use partition value
    dt as day,                -- Use partition value
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

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$SILVER_VIEW_DDL" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting for completion..."

MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ View created successfully"
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        echo "❌ Failed: $REASON"
        exit 1
    fi
    
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

# Step 2: Test the view
echo ""
echo "Step 2: Testing the view..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM health_data_lake.silver_health 
WHERE tenant_id = 'rajasaikatukuri'
LIMIT 1"

QUERY_ID2=$(aws athena start-query-execution \
    --query-string "$TEST_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID2"
echo "Waiting for results..."

MAX_WAIT=90
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID2" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        RESULT=$(aws athena get-query-results \
            --query-execution-id "$QUERY_ID2" \
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
            echo "Now refresh your gold tables:"
            echo ""
            echo "  ./create_gold_tables_for_tenant.sh rajasaikatukuri"
            echo ""
        else
            echo "⚠️  Still returning 0 rows"
            echo ""
            echo "Let's check if the raw table has data without filters:"
            echo ""
            
            # Try querying raw table without partition filters
            RAW_QUERY="SELECT COUNT(*) as count FROM health_data_lake.health_data_raw LIMIT 1"
            
            RAW_QUERY_ID=$(aws athena start-query-execution \
                --query-string "$RAW_QUERY" \
                --work-group "$WORKGROUP" \
                --region "$REGION" \
                --query-execution-context "Database=$DATABASE" \
                --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
                --query 'QueryExecutionId' \
                --output text)
            
            sleep 10
            RAW_STATUS=$(aws athena get-query-execution \
                --query-execution-id "$RAW_QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.State' \
                --output text 2>/dev/null || echo "UNKNOWN")
            
            if [ "$RAW_STATUS" = "SUCCEEDED" ]; then
                RAW_RESULT=$(aws athena get-query-results \
                    --query-execution-id "$RAW_QUERY_ID" \
                    --region "$REGION" \
                    --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
                    --output text 2>/dev/null || echo "0")
                echo "  Total rows in raw table (no filters): $RAW_RESULT"
                echo ""
                if [ "$RAW_RESULT" = "0" ]; then
                    echo "  ⚠️  The Parquet files might be empty or unreadable"
                    echo "  Check the files directly or run check_parquet_schema.py"
                fi
            fi
        fi
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID2" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
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



