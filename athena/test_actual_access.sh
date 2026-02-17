#!/bin/bash
# Test actual S3 and KMS access with current credentials

set -e

BUCKET="health-data-lake-640768199126-us-east-2"
REGION="us-east-2"
TENANT_ID="rajasaikatukuri"
KMS_KEY="6bd581f1-3815-47d1-8d9f-33e7edb1339a"

echo "=========================================="
echo "Testing Actual Access"
echo "=========================================="
echo ""

# Step 1: Verify current identity
echo "Step 1: Verifying AWS identity..."
CURRENT_IDENTITY=$(aws sts get-caller-identity 2>/dev/null || echo "{}")
echo "$CURRENT_IDENTITY" | jq '.' 2>/dev/null || echo "$CURRENT_IDENTITY"
echo ""

# Step 2: Test S3 list
echo "Step 2: Testing S3 list access..."
echo "Command: aws s3 ls s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/"
echo ""

S3_LIST_OUTPUT=$(aws s3 ls "s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/" 2>&1)
S3_LIST_EXIT=$?

if [ $S3_LIST_EXIT -eq 0 ]; then
    echo "✅ S3 list works!"
    echo "$S3_LIST_OUTPUT" | head -5
else
    echo "❌ S3 list failed:"
    echo "$S3_LIST_OUTPUT"
    echo ""
    
    # Check for specific error types
    if [[ "$S3_LIST_OUTPUT" == *"AccessDenied"* ]] || [[ "$S3_LIST_OUTPUT" == *"403"* ]]; then
        echo ""
        echo "⚠️  Access Denied - Possible causes:"
        echo "   1. Bucket policy blocking access"
        echo "   2. Bucket is in different AWS account"
        echo "   3. Credentials don't match the account"
    fi
    
    if [[ "$S3_LIST_OUTPUT" == *"NoSuchBucket"* ]] || [[ "$S3_LIST_OUTPUT" == *"404"* ]]; then
        echo ""
        echo "⚠️  Bucket not found - Check bucket name"
    fi
fi

echo ""

# Step 3: Test S3 get object (if list works)
if [ $S3_LIST_EXIT -eq 0 ]; then
    echo "Step 3: Testing S3 get object access..."
    
    # Try to find a file
    FIRST_FILE=$(aws s3 ls "s3://$BUCKET/health-data/raw/tenant_id=$TENANT_ID/dt=2026-01-04/" --recursive 2>/dev/null | head -1 | awk '{print $4}' || echo "")
    
    if [ -n "$FIRST_FILE" ]; then
        echo "Testing access to: $FIRST_FILE"
        S3_GET_OUTPUT=$(aws s3 cp "s3://$BUCKET/$FIRST_FILE" - --region "$REGION" 2>&1 | head -c 100 || echo "FAILED")
        
        if [ "$S3_GET_OUTPUT" != "FAILED" ] && [ -n "$S3_GET_OUTPUT" ]; then
            echo "✅ S3 get object works!"
        else
            echo "❌ S3 get object failed"
        fi
    else
        echo "⚠️  No files found to test"
    fi
    echo ""
fi

# Step 4: Check KMS permissions (workgroup uses KMS encryption)
echo "Step 4: Checking KMS permissions..."
echo "Workgroup uses KMS key: $KMS_KEY"
echo ""

KMS_TEST=$(aws kms describe-key --key-id "$KMS_KEY" --region "$REGION" 2>&1)
KMS_EXIT=$?

if [ $KMS_EXIT -eq 0 ]; then
    echo "✅ Can access KMS key"
    KEY_ARN=$(echo "$KMS_TEST" | jq -r '.KeyMetadata.Arn' 2>/dev/null || echo "Unknown")
    echo "   Key ARN: $KEY_ARN"
else
    echo "❌ Cannot access KMS key:"
    echo "$KMS_TEST" | head -3
    echo ""
    echo "⚠️  This might be the issue!"
    echo "   The workgroup uses KMS encryption for query results."
    echo "   You need KMS permissions even if S3 works."
    echo ""
    echo "   Add this policy to your user:"
    echo "   - AWS managed: AWSKeyManagementServicePowerUser"
    echo "   - Or custom policy with kms:Decrypt, kms:DescribeKey"
fi

echo ""

# Step 5: Check bucket account
echo "Step 5: Checking bucket account..."
echo "Your account ID: 640768199126"
echo ""

BUCKET_ACCOUNT=$(aws s3api get-bucket-location --bucket "$BUCKET" 2>&1 || echo "ERROR")
if [[ "$BUCKET_ACCOUNT" != *"ERROR"* ]]; then
    echo "✅ Bucket exists and is accessible"
    echo "   Location: $BUCKET_ACCOUNT"
else
    echo "⚠️  Could not verify bucket account"
fi

echo ""

# Step 6: Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ $S3_LIST_EXIT -eq 0 ]; then
    echo "✅ S3 access works!"
    echo ""
    echo "If Athena still fails, the issue might be:"
    echo "  1. KMS permissions (check Step 4)"
    echo "  2. Result location bucket permissions"
    echo "  3. Workgroup configuration"
    echo ""
    echo "Next: Test Athena query:"
    echo "  ./try_without_execution_role.sh"
else
    echo "❌ S3 access doesn't work"
    echo ""
    echo "Even though you have S3 permissions in IAM, you might need:"
    echo "  1. Check bucket policy (might be blocking)"
    echo "  2. Verify you're using the correct AWS credentials"
    echo "  3. Check if bucket is in a different account"
fi

echo ""


