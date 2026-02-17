#!/bin/bash
# Fix permissions and refresh gold tables

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"

echo "=========================================="
echo "Fix Permissions & Refresh Gold Tables"
echo "=========================================="
echo ""
echo "Current status:"
echo "  ✅ Gold tables exist and are accessible"
echo "  ❌ Gold tables are empty (0 rows)"
echo "  ❌ Raw table has permission issues"
echo ""
echo "Steps:"
echo "1. Fix IAM permissions for Athena"
echo "2. Test raw table access"
echo "3. Refresh gold tables"
echo ""

# Step 1: Check workgroup configuration
echo "Step 1: Checking Athena workgroup configuration..."
echo ""

WORKGROUP_INFO=$(aws athena get-work-group \
    --work-group "$WORKGROUP" \
    --region "$REGION" 2>/dev/null || echo "")

if [ -z "$WORKGROUP_INFO" ]; then
    echo "⚠️  Could not get workgroup info"
    echo "   Workgroup might not exist or you don't have permissions"
else
    echo "✅ Workgroup found: $WORKGROUP"
    # Try to extract service role if present
    echo ""
    echo "To fix permissions:"
    echo "1. Go to AWS Console → IAM → Roles"
    echo "2. Find the role used by Athena workgroup"
    echo "3. Attach S3 read permissions (see FIX_PERMISSIONS.md)"
fi

echo ""
echo "Step 2: Testing if we can query raw table now..."
echo ""

# Try a simple query
TEST_QUERY="SELECT COUNT(*) as count 
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

if [ -n "$QUERY_ID" ]; then
    echo "Query ID: $QUERY_ID"
    echo "Waiting..."
    
    sleep 15
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
        
        echo "✅ Raw table accessible! Row count: $RESULT"
        echo ""
        
        if [ "$RESULT" != "0" ] && [ -n "$RESULT" ] && [ "$RESULT" != "None" ]; then
            echo "✅✅✅ Great! Raw data is accessible!"
            echo ""
            echo "Step 3: Refreshing gold tables..."
            echo ""
            echo "Run this to refresh gold tables:"
            echo "  ./create_gold_tables_for_tenant.sh $TENANT_ID"
            echo ""
        else
            echo "⚠️  Raw table accessible but has 0 rows"
            echo "   Check if Parquet files are actually populated"
        fi
    elif [ "$STATUS" = "FAILED" ]; then
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null || echo "Unknown")
        
        if [[ "$REASON" == *"Access Denied"* ]] || [[ "$REASON" == *"403"* ]]; then
            echo "❌ Still getting permission errors"
            echo ""
            echo "You need to fix IAM permissions first:"
            echo ""
            echo "1. Go to AWS Console → IAM → Roles"
            echo "2. Find the Athena service role (check workgroup settings)"
            echo "3. Attach this policy:"
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
            echo "Or attach the managed policy: AmazonS3ReadOnlyAccess"
            echo ""
            echo "After fixing permissions, run this script again."
        else
            echo "❌ Query failed: $REASON"
        fi
    else
        echo "⚠️  Query status: $STATUS (may still be running)"
    fi
else
    echo "❌ Could not start query"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "Current state:"
echo "  ✅ Gold tables: Exist and accessible (but empty)"
echo "  ❌ Raw table: Permission issues"
echo ""
echo "Next steps:"
echo "1. Fix IAM permissions (see above or FIX_PERMISSIONS.md)"
echo "2. Once raw table works, refresh gold tables:"
echo "   ./create_gold_tables_for_tenant.sh $TENANT_ID"
echo "3. Then try your chat queries!"
echo ""



