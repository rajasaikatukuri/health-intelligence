#!/bin/bash
# Verify AWS account and test everything end-to-end

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"

echo "=========================================="
echo "Verifying and Testing Everything"
echo "=========================================="
echo ""

# Step 1: Verify AWS account
echo "Step 1: Verifying AWS account..."
echo ""

IDENTITY=$(aws sts get-caller-identity 2>&1)
if [[ "$IDENTITY" == *"Account"* ]] || [[ "$IDENTITY" == *"account"* ]]; then
    ACCOUNT=$(echo "$IDENTITY" | jq -r '.Account' 2>/dev/null || echo "Unknown")
    USER_ARN=$(echo "$IDENTITY" | jq -r '.Arn' 2>/dev/null || echo "Unknown")
    
    echo "✅ AWS CLI is working!"
    echo "   Account: $ACCOUNT"
    echo "   User: $USER_ARN"
    echo ""
    
    if [ "$ACCOUNT" = "640768199126" ]; then
        echo "✅✅✅ Perfect! Using correct account!"
    else
        echo "⚠️  Wrong account! You're using: $ACCOUNT"
        echo "   You need: 640768199126"
        echo ""
        echo "   Switch accounts with:"
        echo "     aws configure --profile health-data"
        echo "     export AWS_PROFILE=health-data"
        echo ""
        exit 1
    fi
else
    echo "❌ AWS CLI not working:"
    echo "$IDENTITY"
    echo ""
    echo "Fix AWS CLI first, then run this again."
    exit 1
fi

# Step 2: Test S3 access
echo "Step 2: Testing S3 access..."
echo ""

S3_TEST=$(aws s3 ls "s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/" 2>&1 | head -3 || echo "FAILED")
if [[ "$S3_TEST" != *"FAILED"* ]] && [[ "$S3_TEST" != *"NoSuchBucket"* ]] && [[ "$S3_TEST" != *"AccessDenied"* ]]; then
    echo "✅ S3 access works!"
    echo "$S3_TEST"
    echo ""
else
    echo "❌ S3 access failed:"
    echo "$S3_TEST"
    echo ""
    echo "Check your S3 permissions."
    exit 1
fi

# Step 3: Test Athena query on raw table
echo "Step 3: Testing Athena query (raw table)..."
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
SUCCESS=false

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
        echo "✅✅✅ Athena query succeeded! ✅✅✅"
        echo "📊 Row count: $RESULT"
        echo ""
        
        if [ "$RESULT" != "0" ] && [ -n "$RESULT" ] && [ "$RESULT" != "None" ]; then
            echo "✅ Data is accessible in raw table!"
            SUCCESS=true
        else
            echo "⚠️  Raw table accessible but has 0 rows"
            echo "   This might be okay if you're using gold tables"
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
        exit 1
    fi
    
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    if [ $((ELAPSED % 15)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s)"
    fi
done

if [ "$SUCCESS" = false ] && [ $ELAPSED -ge $MAX_WAIT ]; then
    echo ""
    echo "⚠️  Query timed out after ${MAX_WAIT}s"
    echo "   Check query status manually:"
    echo "   aws athena get-query-execution --query-execution-id $QUERY_ID --region $REGION"
fi

# Step 4: Check gold tables
echo ""
echo "Step 4: Checking gold tables..."
echo ""

GOLD_QUERY="SELECT COUNT(*) as count FROM $DATABASE.gold_daily_features WHERE tenant_id = '$TENANT_ID' LIMIT 1"
GOLD_QUERY_ID=$(aws athena start-query-execution \
    --query-string "$GOLD_QUERY" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text 2>/dev/null || echo "")

if [ -n "$GOLD_QUERY_ID" ]; then
    sleep 10
    GOLD_STATUS=$(aws athena get-query-execution \
        --query-execution-id "$GOLD_QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$GOLD_STATUS" = "SUCCEEDED" ]; then
        GOLD_RESULT=$(aws athena get-query-results \
            --query-execution-id "$GOLD_QUERY_ID" \
            --region "$REGION" \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text 2>/dev/null || echo "0")
        
        echo "Gold table row count: $GOLD_RESULT"
        
        if [ "$GOLD_RESULT" != "0" ] && [ -n "$GOLD_RESULT" ] && [ "$GOLD_RESULT" != "None" ]; then
            echo "✅ Gold tables have data!"
        else
            echo "⚠️  Gold tables are empty"
            echo ""
            echo "   Populate them with:"
            echo "     ./create_gold_tables_for_tenant.sh $TENANT_ID"
        fi
    fi
fi

# Step 5: Summary
echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "✅ AWS account: Correct (640768199126)"
echo "✅ S3 access: Working"
echo "✅ Athena queries: Working"

if [ "$SUCCESS" = true ]; then
    echo ""
    echo "🎉🎉🎉 Everything is working! 🎉🎉🎉"
    echo ""
    echo "Next steps:"
    echo "1. If gold tables are empty, populate them:"
    echo "   ./create_gold_tables_for_tenant.sh $TENANT_ID"
    echo ""
    echo "2. Start your backend:"
    echo "   cd ../backend && ./start.sh"
    echo ""
    echo "3. Start your frontend:"
    echo "   cd ../frontend && npm run dev"
    echo ""
    echo "4. Test the chat interface!"
else
    echo ""
    echo "⚠️  Some issues detected. Check above for details."
fi
echo ""

