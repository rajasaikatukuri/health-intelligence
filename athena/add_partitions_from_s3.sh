#!/bin/bash
# Add partitions to Athena table based on what's actually in S3

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="${1:-rajasaikatukuri}"

echo "=========================================="
echo "Adding Partitions from S3"
echo "=========================================="
echo ""
echo "Tenant ID: $TENANT_ID"
echo ""

# Find all partitions for this tenant
echo "Discovering partitions in S3..."
echo ""

PARTITIONS=$(aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | \
    grep -i "tenant_id=$TENANT_ID" | \
    grep -oP "tenant_id=[^/]+/dt=[^/]+" | \
    sort -u)

if [ -z "$PARTITIONS" ]; then
    echo "❌ No partitions found for tenant_id=$TENANT_ID"
    echo ""
    echo "Trying to find any partitions..."
    PARTITIONS=$(aws s3 ls "s3://$BUCKET/health-data/raw/" --recursive 2>/dev/null | \
        grep -oP "tenant_id=[^/]+/dt=[^/]+" | \
        sort -u | head -20)
fi

if [ -z "$PARTITIONS" ]; then
    echo "❌ No partition structure detected"
    echo ""
    echo "Your data might not be partitioned. Options:"
    echo "1. Data is flat - recreate table without partitions"
    echo "2. Different partition structure - check S3 manually"
    exit 1
fi

PARTITION_COUNT=$(echo "$PARTITIONS" | wc -l | tr -d ' ')
echo "Found $PARTITION_COUNT partitions"
echo ""

# Add partitions
echo "Adding partitions to Athena table..."
echo ""

ADDED=0
FAILED=0

echo "$PARTITIONS" | while read -r partition; do
    TENANT=$(echo "$partition" | grep -oP "tenant_id=\K[^/]+")
    DT=$(echo "$partition" | grep -oP "dt=\K[^/]+")
    
    if [ -n "$TENANT" ] && [ -n "$DT" ]; then
        ADD_PARTITION_QUERY="ALTER TABLE $DATABASE.health_data_raw ADD IF NOT EXISTS PARTITION (tenant_id='$TENANT', dt='$DT')"
        
        echo "Adding: tenant_id=$TENANT, dt=$DT"
        
        QUERY_ID=$(aws athena start-query-execution \
            --query-string "$ADD_PARTITION_QUERY" \
            --work-group "$WORKGROUP" \
            --region "$REGION" \
            --query 'QueryExecutionId' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$QUERY_ID" ]; then
            # Quick check if it succeeded (don't wait too long)
            sleep 1
            STATUS=$(aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.State' \
                --output text 2>/dev/null || echo "UNKNOWN")
            
            if [ "$STATUS" = "SUCCEEDED" ]; then
                echo "  ✅ Added"
                ADDED=$((ADDED + 1))
            else
                echo "  ⚠️  Status: $STATUS"
            fi
        else
            echo "  ❌ Failed to start query"
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo ""
echo "=========================================="
echo "Partition Addition Complete"
echo "=========================================="
echo ""
echo "Added partitions (may still be processing in background)"
echo ""

# Test query
echo "Testing data access..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
LIMIT 1"

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$TEST_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting for results..."

MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        RESULTS=$(aws athena get-query-results \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text 2>/dev/null || echo "0")
        
        echo ""
        echo "✅ Query succeeded!"
        echo "📊 Row count: $RESULTS"
        echo ""
        
        if [ "$RESULTS" != "0" ] && [ -n "$RESULTS" ]; then
            echo "✅ Data is accessible! Now refresh gold tables:"
            echo ""
            echo "  ./create_gold_tables_for_tenant.sh $TENANT_ID"
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

echo ""


