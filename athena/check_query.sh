#!/bin/bash
# Check status of a stuck Athena query

QUERY_ID="${1:-45d5c04e-0057-45a5-a04b-c6abf6963103}"
REGION="us-east-2"

echo "Checking query: $QUERY_ID"
echo ""

STATUS=$(aws athena get-query-execution \
    --query-execution-id "$QUERY_ID" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null)

echo "Status: $STATUS"
echo ""

if [ "$STATUS" = "RUNNING" ] || [ "$STATUS" = "QUEUED" ]; then
    echo "Query is still running. You can:"
    echo "1. Wait for it to complete"
    echo "2. Cancel it: aws athena stop-query-execution --query-execution-id $QUERY_ID --region $REGION"
    echo "3. Continue with next steps (table might already exist)"
elif [ "$STATUS" = "SUCCEEDED" ]; then
    echo "✅ Query succeeded!"
elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
    REASON=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.StateChangeReason' \
        --output text 2>/dev/null)
    echo "❌ Query failed/cancelled"
    echo "Reason: $REASON"
fi

echo ""
echo "Full details:"
aws athena get-query-execution \
    --query-execution-id "$QUERY_ID" \
    --region "$REGION" \
    --output json | jq '.QueryExecution.Status'






