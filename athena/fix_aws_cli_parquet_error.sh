#!/bin/bash
# Fix AWS CLI parquet output error

set -e

echo "=========================================="
echo "Fixing AWS CLI Parquet Error"
echo "=========================================="
echo ""

# Check for environment variable
if [ -n "$AWS_DEFAULT_OUTPUT" ]; then
    echo "Found environment variable: AWS_DEFAULT_OUTPUT=$AWS_DEFAULT_OUTPUT"
    echo ""
    echo "This might be overriding your config!"
    echo "Unset it with: unset AWS_DEFAULT_OUTPUT"
    echo ""
fi

# Check all profiles
echo "Checking all AWS profiles..."
echo ""

if [ -f ~/.aws/config ]; then
    echo "Profiles in ~/.aws/config:"
    grep -E "^\[profile.*\]|^\[default\]" ~/.aws/config | while read line; do
        PROFILE=$(echo "$line" | sed 's/\[profile //;s/\]//;s/\[//;s/\]//')
        echo "  Profile: $PROFILE"
        OUTPUT=$(aws configure get output --profile "$PROFILE" 2>/dev/null || echo "not set")
        echo "    Output format: $OUTPUT"
        if [ "$OUTPUT" = "parquet" ]; then
            echo "    ⚠️  FIXING: Setting to json..."
            aws configure set output json --profile "$PROFILE"
        fi
        echo ""
    done
fi

# Fix default
echo "Fixing default profile..."
aws configure set output json

# Also check credentials file for any output settings (unlikely but possible)
if [ -f ~/.aws/credentials ]; then
    echo ""
    echo "Checking ~/.aws/credentials for output settings..."
    if grep -q "output" ~/.aws/credentials; then
        echo "  ⚠️  Found 'output' in credentials file (unusual)"
        echo "  You might need to remove it manually"
    fi
fi

echo ""
echo "✅ Fixed all profiles!"
echo ""

# Test
echo "Testing AWS CLI..."
echo ""

# Unset environment variable if it exists
unset AWS_DEFAULT_OUTPUT 2>/dev/null || true

IDENTITY=$(aws sts get-caller-identity 2>&1)
if [[ "$IDENTITY" == *"Account"* ]] || [[ "$IDENTITY" == *"account"* ]]; then
    echo "✅ AWS CLI works!"
    echo ""
    echo "$IDENTITY" | jq '.' 2>/dev/null || echo "$IDENTITY"
    echo ""
    ACCOUNT=$(echo "$IDENTITY" | jq -r '.Account' 2>/dev/null || echo "Unknown")
    if [ -n "$ACCOUNT" ] && [ "$ACCOUNT" != "null" ] && [ "$ACCOUNT" != "Unknown" ]; then
        echo "Current account: $ACCOUNT"
        echo ""
        if [ "$ACCOUNT" = "640768199126" ]; then
            echo "✅✅✅ Perfect! You're using the correct account!"
        else
            echo "⚠️  You're using account: $ACCOUNT"
            echo "   You need account: 640768199126"
            echo ""
            echo "To switch accounts, run:"
            echo "  aws configure --profile health-data"
            echo "  export AWS_PROFILE=health-data"
        fi
    fi
else
    echo "❌ Still having issues:"
    echo "$IDENTITY"
    echo ""
    echo "Try manually:"
    echo "  1. Check: echo \$AWS_DEFAULT_OUTPUT"
    echo "  2. If set, unset it: unset AWS_DEFAULT_OUTPUT"
    echo "  3. Check: aws configure get output"
    echo "  4. If 'parquet', fix it: aws configure set output json"
fi
echo ""


