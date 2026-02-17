#!/bin/bash
# Check if Parquet files actually contain data

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"

echo "=========================================="
echo "Checking if Parquet Files Have Data"
echo "=========================================="
echo ""

# Query without ANY filters to see if table has data at all
echo "Test: Querying raw table WITHOUT any filters..."
echo "This will scan all partitions to see if there's any data."
echo ""

QUERY="SELECT COUNT(*) as total_rows FROM $DATABASE.health_data_raw"

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
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
        RESULT=$(aws athena get-query-results \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text 2>/dev/null || echo "0")
        
        echo ""
        echo "✅ Query succeeded!"
        echo ""
        echo "📊 Total rows in entire table (all partitions): $RESULT"
        echo ""
        
        if [ "$RESULT" != "0" ] && [ -n "$RESULT" ] && [ "$RESULT" != "None" ]; then
            echo "✅ Data exists! The issue is with partition filtering."
            echo ""
            echo "This means:"
            echo "  - Parquet files contain data ✅"
            echo "  - Table can read the files ✅"
            echo "  - Partition filtering might not be working correctly"
            echo ""
            echo "Solution: The Parquet files likely contain tenant_id/dt as columns."
            echo "We need to either:"
            echo "  1. Remove tenant_id/dt from Parquet files (not practical)"
            echo "  2. Query using the column values instead of partition values"
            echo ""
            echo "Let's try querying using column filters:"
            echo ""
            
            # Try querying with column-based filters
            COL_QUERY="SELECT COUNT(*) as count 
            FROM $DATABASE.health_data_raw 
            WHERE \"tenant_id\" = 'rajasaikatukuri' 
              AND \"dt\" = '2026-01-04'"
            
            echo "Running query with column filters (using quotes)..."
            COL_QUERY_ID=$(aws athena start-query-execution \
                --query-string "$COL_QUERY" \
                --work-group "$WORKGROUP" \
                --region "$REGION" \
                --query-execution-context "Database=$DATABASE" \
                --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
                --query 'QueryExecutionId' \
                --output text)
            
            sleep 15
            COL_STATUS=$(aws athena get-query-execution \
                --query-execution-id "$COL_QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.State' \
                --output text 2>/dev/null || echo "UNKNOWN")
            
            if [ "$COL_STATUS" = "SUCCEEDED" ]; then
                COL_RESULT=$(aws athena get-query-results \
                    --query-execution-id "$COL_QUERY_ID" \
                    --region "$REGION" \
                    --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
                    --output text 2>/dev/null || echo "0")
                echo "  Result with column filters: $COL_RESULT rows"
            fi
        else
            echo "❌ No data found in table at all"
            echo ""
            echo "This means:"
            echo "  - Parquet files might be empty"
            echo "  - Files might not be readable"
            echo "  - Schema mismatch preventing data read"
            echo ""
            echo "Next step: Check Parquet file schema:"
            echo "  cd ../backend"
            echo "  source venv/bin/activate"
            echo "  python3 ../athena/check_parquet_schema.py"
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
        break
    fi
    
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s)"
    fi
done

echo ""



