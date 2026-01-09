#!/bin/bash
# Diagnose IAM permissions issue

set -e

REGION="us-east-2"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"

echo "=========================================="
echo "Diagnosing IAM Permissions"
echo "=========================================="
echo ""

# Step 1: Get workgroup details
echo "Step 1: Getting workgroup configuration..."
echo ""

WORKGROUP_JSON=$(aws athena get-work-group \
    --work-group "$WORKGROUP" \
    --region "$REGION" 2>/dev/null || echo "{}")

if [ "$WORKGROUP_JSON" != "{}" ]; then
    echo "Workgroup configuration:"
    echo "$WORKGROUP_JSON" | jq '.' 2>/dev/null || echo "$WORKGROUP_JSON"
    echo ""
    
    # Try to extract role ARN
    ROLE_ARN=$(echo "$WORKGROUP_JSON" | jq -r '.WorkGroup.Configuration.ResultConfiguration.EncryptionConfiguration.KmsKey' 2>/dev/null || echo "")
    
    # Check for execution role
    EXECUTION_ROLE=$(echo "$WORKGROUP_JSON" | jq -r '.WorkGroup.Configuration.ExecutionRole' 2>/dev/null || echo "")
    
    if [ -n "$EXECUTION_ROLE" ] && [ "$EXECUTION_ROLE" != "null" ]; then
        echo "✅ Found execution role: $EXECUTION_ROLE"
        ROLE_NAME=$(echo "$EXECUTION_ROLE" | awk -F'/' '{print $NF}')
        echo "   Role name: $ROLE_NAME"
    else
        echo "⚠️  No execution role found in workgroup"
        echo "   Athena might be using default service role"
    fi
else
    echo "⚠️  Could not get workgroup details"
fi

# Step 2: List roles that might be used
echo ""
echo "Step 2: Checking common Athena roles..."
echo ""

# Common role patterns
ROLE_PATTERNS=(
    "*Athena*"
    "*athena*"
    "*health*"
    "*data*"
)

for pattern in "${ROLE_PATTERNS[@]}"; do
    ROLES=$(aws iam list-roles --query "Roles[?contains(RoleName, '$pattern')].RoleName" --output text 2>/dev/null || echo "")
    if [ -n "$ROLES" ]; then
        echo "Roles matching '$pattern':"
        echo "$ROLES" | tr '\t' '\n' | head -5
        echo ""
    fi
done

# Step 3: Check bucket policy
echo ""
echo "Step 3: Checking S3 bucket policy..."
echo ""

BUCKET_POLICY=$(aws s3api get-bucket-policy \
    --bucket "$BUCKET" \
    --region "$REGION" 2>/dev/null || echo "{}")

if [ "$BUCKET_POLICY" != "{}" ]; then
    echo "Bucket policy exists:"
    echo "$BUCKET_POLICY" | jq -r '.Policy' 2>/dev/null | jq '.' || echo "$BUCKET_POLICY"
    echo ""
else
    echo "⚠️  No bucket policy found"
    echo "   Bucket might rely on IAM roles only"
    echo ""
fi

# Step 4: Test with different approaches
echo ""
echo "Step 4: Testing alternative approaches..."
echo ""

echo "Option A: Check if we can list bucket (using your credentials)..."
aws s3 ls "s3://$BUCKET/health-data/raw/" 2>/dev/null && echo "  ✅ You can list bucket" || echo "  ❌ Cannot list bucket"

echo ""
echo "Option B: Try querying with explicit result location..."
echo "  (Some workgroups require explicit result location permissions)"

# Step 5: Recommendations
echo ""
echo "=========================================="
echo "Recommendations"
echo "=========================================="
echo ""
echo "If you've attached the policy but still get errors:"
echo ""
echo "1. Verify the role is correct:"
echo "   - Go to Athena Console → Workgroups → $WORKGROUP"
echo "   - Check 'Execution role' or 'Service role'"
echo "   - Make sure you attached policy to THAT role"
echo ""
echo "2. Check bucket policy (might be blocking):"
echo "   - Go to S3 Console → $BUCKET → Permissions → Bucket policy"
echo "   - Make sure it allows Athena service"
echo ""
echo "3. Wait a few minutes (IAM changes can take time to propagate)"
echo ""
echo "4. Try using a different result location:"
echo "   - Some workgroups need explicit result location permissions"
echo ""
echo "5. Check if workgroup has result encryption enabled:"
echo "   - If encrypted, the role needs KMS permissions too"
echo ""
echo "6. Alternative: Use your user credentials directly"
echo "   - If you have admin access, Athena might use your user credentials"
echo "   - Make sure your user has S3 permissions"
echo ""

# Step 6: Quick test with user credentials
echo ""
echo "Step 6: Testing your user credentials..."
echo ""

CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "Unknown")
echo "Current AWS identity: $CURRENT_USER"
echo ""

# Check if user has S3 permissions
CAN_READ=$(aws s3 ls "s3://$BUCKET/health-data/raw/tenant_id=rajasaikatukuri/" 2>/dev/null && echo "yes" || echo "no")
echo "Can you read S3 with your credentials: $CAN_READ"

if [ "$CAN_READ" = "yes" ]; then
    echo ""
    echo "✅ Your credentials can read S3!"
    echo "   The issue might be with the Athena service role."
    echo "   Try: Use a workgroup without execution role (uses your credentials)"
fi

echo ""


