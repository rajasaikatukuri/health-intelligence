#!/bin/bash
# Fix AWS CLI output format

set -e

echo "=========================================="
echo "Fixing AWS CLI Output Format"
echo "=========================================="
echo ""
echo "Your AWS CLI output is set to 'parquet' which is invalid."
echo "Valid formats: json, yaml, yaml-stream, text, table"
echo ""

# Check current setting
CURRENT_OUTPUT=$(aws configure get output 2>/dev/null || echo "not set")
echo "Current output format: $CURRENT_OUTPUT"
echo ""

# Fix it
echo "Setting output format to 'json' (recommended)..."
aws configure set output json

echo ""
echo "✅ Output format fixed!"
echo ""

# Verify
echo "Verifying..."
NEW_OUTPUT=$(aws configure get output)
echo "New output format: $NEW_OUTPUT"
echo ""

# Test
echo "Testing AWS CLI..."
IDENTITY=$(aws sts get-caller-identity 2>&1)
if [[ "$IDENTITY" == *"Account"* ]]; then
    echo "✅ AWS CLI works!"
    echo ""
    echo "$IDENTITY" | jq '.' 2>/dev/null || echo "$IDENTITY"
    echo ""
    ACCOUNT=$(echo "$IDENTITY" | jq -r '.Account' 2>/dev/null || echo "Unknown")
    echo "Current account: $ACCOUNT"
    echo ""
    if [ "$ACCOUNT" = "640768199126" ]; then
        echo "✅✅✅ Perfect! You're using the correct account!"
    else
        echo "⚠️  You're still using account: $ACCOUNT"
        echo "   You need to switch to account: 640768199126"
        echo "   Run: aws configure --profile health-data"
    fi
else
    echo "❌ Still having issues:"
    echo "$IDENTITY"
fi
echo ""


