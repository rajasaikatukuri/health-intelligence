#!/bin/bash
# Check which AWS account has access to the data

set -e

echo "=========================================="
echo "Checking AWS Account Access"
echo "=========================================="
echo ""

# Current account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "Unknown")
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "Unknown")

echo "Current AWS Account: $CURRENT_ACCOUNT"
echo "Current User: $CURRENT_USER"
echo ""

# Test buckets in both accounts
BUCKET_248894="health-data-lake-248894199474-us-east-2"
BUCKET_640768="health-data-lake-640768199126-us-east-2"

echo "Testing bucket access..."
echo ""

# Test account 248894199474 bucket
echo "1. Testing: s3://$BUCKET_248894/"
TEST_248894=$(aws s3 ls "s3://$BUCKET_248894/health-data/raw/" 2>&1 | head -3 || echo "FAILED")
if [[ "$TEST_248894" != *"FAILED"* ]] && [[ "$TEST_248894" != *"NoSuchBucket"* ]] && [[ "$TEST_248894" != *"AccessDenied"* ]]; then
    echo "   ✅ Can access $BUCKET_248894"
    echo "   $TEST_248894"
    echo ""
    echo "   ⚠️  Your data might be in account 248894199474!"
    echo "   Update scripts to use: $BUCKET_248894"
else
    echo "   ❌ Cannot access $BUCKET_248894"
    if [[ "$TEST_248894" == *"NoSuchBucket"* ]]; then
        echo "      (Bucket doesn't exist)"
    elif [[ "$TEST_248894" == *"AccessDenied"* ]]; then
        echo "      (Access denied - might exist but no permission)"
    fi
fi
echo ""

# Test account 640768199126 bucket
echo "2. Testing: s3://$BUCKET_640768/"
TEST_640768=$(aws s3 ls "s3://$BUCKET_640768/health-data/raw/" 2>&1 | head -3 || echo "FAILED")
if [[ "$TEST_640768" != *"FAILED"* ]] && [[ "$TEST_640768" != *"NoSuchBucket"* ]] && [[ "$TEST_640768" != *"AccessDenied"* ]]; then
    echo "   ✅ Can access $BUCKET_640768"
    echo "   $TEST_640768"
    echo ""
    echo "   ✅ Your data is accessible!"
else
    echo "   ❌ Cannot access $BUCKET_640768"
    if [[ "$TEST_640768" == *"NoSuchBucket"* ]]; then
        echo "      (Bucket doesn't exist)"
    elif [[ "$TEST_640768" == *"AccessDenied"* ]]; then
        echo "      (Access denied - cross-account issue)"
        echo ""
        echo "      ⚠️  This is a CROSS-ACCOUNT access issue!"
        echo "      Your account: $CURRENT_ACCOUNT"
        echo "      Bucket account: 640768199126"
        echo ""
        echo "      Solutions:"
        echo "      1. Use credentials from account 640768199126"
        echo "      2. Add bucket policy to allow your account"
        echo "      3. Assume a role in account 640768199126"
    fi
fi
echo ""

# List all accessible buckets
echo "3. Listing all S3 buckets you can access..."
echo ""
ALL_BUCKETS=$(aws s3 ls 2>/dev/null | grep -i "health\|data" || echo "None found")
if [ -n "$ALL_BUCKETS" ] && [[ "$ALL_BUCKETS" != "None found" ]]; then
    echo "   Health/data related buckets:"
    echo "$ALL_BUCKETS" | sed 's/^/      /'
else
    echo "   No health/data buckets found"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "Your account: $CURRENT_ACCOUNT"
echo ""

if [[ "$TEST_248894" == *"✅"* ]]; then
    echo "✅ Use bucket: $BUCKET_248894"
    echo "   Update all scripts to use this bucket!"
elif [[ "$TEST_640768" == *"✅"* ]]; then
    echo "✅ Use bucket: $BUCKET_640768"
    echo "   Everything should work!"
else
    echo "❌ Cannot access either bucket"
    echo ""
    echo "Next steps:"
    echo "1. Check if you have credentials for account 640768199126"
    echo "2. Or set up cross-account access (see fix_cross_account_access.md)"
fi
echo ""

