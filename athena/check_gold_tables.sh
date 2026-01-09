#!/bin/bash
# Check if gold tables already have data and can be queried

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"

echo "=========================================="
echo "Checking Gold Tables"
echo "=========================================="
echo ""
echo "Gold tables location: s3://$BUCKET/health-data/gold/"
echo ""

# Test each gold table
GOLD_TABLES=(
    "gold_daily_features"
    "gold_weekly_features"
    "gold_daily_by_type"
)

for table in "${GOLD_TABLES[@]}"; do
    echo "Testing: $table"
    echo ""
    
    TEST_QUERY="SELECT COUNT(*) as row_count 
    FROM $DATABASE.$table 
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
    
    echo "  Query ID: $QUERY_ID"
    echo "  Waiting..."
    
    MAX_WAIT=60
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
            
            echo "  ✅ $table: $RESULT rows"
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            REASON=$(aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text 2>/dev/null || echo "Unknown")
            
            if [[ "$REASON" == *"does not exist"* ]] || [[ "$REASON" == *"TABLE_NOT_FOUND"* ]]; then
                echo "  ⚠️  Table doesn't exist yet"
            elif [[ "$REASON" == *"Access Denied"* ]] || [[ "$REASON" == *"403"* ]]; then
                echo "  ❌ Permission denied (same issue as raw table)"
            else
                echo "  ❌ Failed: $REASON"
            fi
            break
        fi
        
        sleep 3
        ELAPSED=$((ELAPSED + 3))
    done
    
    echo ""
done

echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "If gold tables have data, you can use them directly!"
echo "The chat interface queries gold tables, so it might work."
echo ""
echo "If you see permission errors, the Athena workgroup needs:"
echo "1. S3 read permissions for: s3://$BUCKET/health-data/*"
echo "2. Check IAM role attached to workgroup: $WORKGROUP"
echo ""
echo "To fix permissions, add this policy to the Athena service role:"
echo ""
cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET",
                "arn:aws:s3:::$BUCKET/*"
            ]
        }
    ]
}
EOF
echo ""


