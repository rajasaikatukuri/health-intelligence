#!/bin/bash
# Add partitions for existing data

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"

echo "=========================================="
echo "Adding Partitions for Your Data"
echo "=========================================="
echo ""
echo "Tenant ID: $TENANT_ID"
echo ""

# Find all date partitions for this tenant
echo "Step 1: Finding all date partitions..."
echo ""

DATES=$(aws s3 ls "s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/" 2>/dev/null | \
    grep "PRE" | \
    grep -oP "dt=\K[^/]+" | \
    sort)

if [ -z "$DATES" ]; then
    echo "⚠️  Could not auto-detect dates, using known date: 2026-01-04"
    DATES="2026-01-04"
else
    DATE_COUNT=$(echo "$DATES" | wc -l | tr -d ' ')
    echo "Found $DATE_COUNT date partitions:"
    echo "$DATES"
fi

echo ""
echo "Step 2: Adding partitions to Athena table..."
echo ""

ADDED=0
FAILED=0

for DT in $DATES; do
    echo "Adding partition: tenant_id=$TENANT_ID, dt=$DT"
    
    ADD_PARTITION_QUERY="ALTER TABLE $DATABASE.health_data_raw ADD IF NOT EXISTS PARTITION (tenant_id='$TENANT_ID', dt='$DT')"
    
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "$ADD_PARTITION_QUERY" \
        --work-group "$WORKGROUP" \
        --region "$REGION" \
        --query 'QueryExecutionId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$QUERY_ID" ]; then
        # Wait a moment for completion
        sleep 2
        STATUS=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.State' \
            --output text 2>/dev/null || echo "UNKNOWN")
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "  ✅ Added successfully"
            ADDED=$((ADDED + 1))
        elif [ "$STATUS" = "FAILED" ]; then
            REASON=$(aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text 2>/dev/null || echo "Unknown")
            
            # Check if partition already exists (that's OK)
            if [[ "$REASON" == *"already exists"* ]] || [[ "$REASON" == *"duplicate"* ]]; then
                echo "  ℹ️  Already exists (that's OK)"
                ADDED=$((ADDED + 1))
            else
                echo "  ❌ Failed: $REASON"
                FAILED=$((FAILED + 1))
            fi
        else
            echo "  ⚠️  Status: $STATUS (may still be processing)"
            ADDED=$((ADDED + 1))
        fi
    else
        echo "  ❌ Failed to start query"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "=========================================="
echo "Partition Addition Summary"
echo "=========================================="
echo "Added: $ADDED"
if [ "$FAILED" -gt 0 ]; then
    echo "Failed: $FAILED"
fi
echo ""

# Step 3: Test data access
echo "Step 3: Testing data access..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
  AND dt = '2026-01-04'
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

MAX_WAIT=90
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo ""
        echo "✅ Query succeeded!"
        
        # Get results
        RESULTS=$(aws athena get-query-results \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text 2>/dev/null || echo "0")
        
        echo ""
        echo "📊 Row count for dt=2026-01-04: $RESULTS"
        echo ""
        
        if [ "$RESULTS" != "0" ] && [ -n "$RESULTS" ] && [ "$RESULTS" != "None" ]; then
            echo "✅✅✅ SUCCESS! Data is accessible! ✅✅✅"
            echo ""
            echo "Now let's check all dates:"
            echo ""
            
            # Query all dates
            ALL_DATES_QUERY="SELECT DISTINCT dt, COUNT(*) as row_count 
            FROM $DATABASE.health_data_raw 
            WHERE tenant_id = '$TENANT_ID'
            GROUP BY dt 
            ORDER BY dt DESC"
            
            echo "Querying all available dates..."
            ALL_QUERY_ID=$(aws athena start-query-execution \
                --query-string "$ALL_DATES_QUERY" \
                --work-group "$WORKGROUP" \
                --region "$REGION" \
                --query-execution-context "Database=$DATABASE" \
                --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
                --query 'QueryExecutionId' \
                --output text)
            
            echo "Query ID: $ALL_QUERY_ID"
            echo "Waiting..."
            
            sleep 10
            ALL_STATUS=$(aws athena get-query-execution \
                --query-execution-id "$ALL_QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.State' \
                --output text 2>/dev/null || echo "UNKNOWN")
            
            if [ "$ALL_STATUS" = "SUCCEEDED" ]; then
                echo ""
                echo "Available dates and row counts:"
                aws athena get-query-results \
                    --query-execution-id "$ALL_QUERY_ID" \
                    --region "$REGION" \
                    --query 'ResultSet.Rows[1:].Data[*].VarCharValue' \
                    --output table 2>/dev/null || echo "Could not format results"
            fi
            
            echo ""
            echo "=========================================="
            echo "Next Step: Refresh Gold Tables"
            echo "=========================================="
            echo ""
            echo "Now refresh your gold tables:"
            echo ""
            echo "  cd $(dirname "$0")"
            echo "  ./create_gold_tables_for_tenant.sh $TENANT_ID"
            echo ""
            echo "Then try your queries in the chat interface! 🎉"
        else
            echo "⚠️  Query returned 0 rows or no data"
            echo "   This might mean:"
            echo "   - Partition was added but data isn't accessible yet (wait 1-2 minutes)"
            echo "   - Data format doesn't match expected schema"
            echo "   - Files are empty"
        fi
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        echo ""
        echo "❌ Query failed: $REASON"
        echo ""
        echo "Troubleshooting:"
        echo "1. Check table location matches: s3://$BUCKET/health-data/raw/"
        echo "2. Verify partition was added successfully"
        echo "3. Check Parquet file schema matches table schema"
        break
    fi
    
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s)"
    fi
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo ""
    echo "⚠️  Query timed out after ${MAX_WAIT}s"
    echo "   Check status manually with Query ID: $QUERY_ID"
fi

echo ""


