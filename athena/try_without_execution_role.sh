#!/bin/bash
# Try querying without execution role (uses your user credentials)

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"

echo "=========================================="
echo "Testing with User Credentials"
echo "=========================================="
echo ""
echo "If your user has S3 permissions, we can query directly."
echo ""

# Check current user
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "Unknown")
echo "Current AWS identity: $CURRENT_USER"
echo ""

# Test S3 access
echo "Testing S3 access..."
CAN_READ=$(aws s3 ls "s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/" 2>/dev/null && echo "yes" || echo "no")

if [ "$CAN_READ" = "no" ]; then
    echo "❌ Your user cannot read S3"
    echo "   You need S3 permissions on your user/role"
    exit 1
fi

echo "✅ Your user can read S3"
echo ""

# Try query - some workgroups use user credentials if no execution role
echo "Testing Athena query (may use your credentials if no execution role)..."
echo ""

TEST_QUERY="SELECT COUNT(*) as row_count 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
  AND dt = '2026-01-04'
LIMIT 1"

QUERY_ID=$(aws athena start-query-execution \
    --query-string "$TEST_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text 2>/dev/null || echo "")

if [ -z "$QUERY_ID" ]; then
    echo "❌ Could not start query"
    exit 1
fi

echo "Query ID: $QUERY_ID"
echo "Waiting for results..."

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
        echo "✅✅✅ SUCCESS! Query worked! ✅✅✅"
        echo "📊 Row count: $RESULT"
        echo ""
        
        if [ "$RESULT" != "0" ] && [ -n "$RESULT" ] && [ "$RESULT" != "None" ]; then
            echo "✅ Data is accessible!"
            echo ""
            echo "Now refresh gold tables:"
            echo "  ./create_gold_tables_for_tenant.sh $TENANT_ID"
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
        
        if [[ "$REASON" == *"Access Denied"* ]] || [[ "$REASON" == *"403"* ]]; then
            echo ""
            echo "The workgroup is using an execution role that still lacks permissions."
            echo ""
            echo "Solutions:"
            echo "1. Find the exact role in workgroup settings"
            echo "2. Attach S3 permissions to that specific role"
            echo "3. Or create a new workgroup without execution role"
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



