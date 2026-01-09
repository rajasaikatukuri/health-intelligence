#!/bin/bash
# Test data access with various queries to diagnose the issue

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"
TENANT_ID="rajasaikatukuri"
DT="2026-01-04"

echo "=========================================="
echo "Testing Data Access"
echo "=========================================="
echo ""

# Test 1: Query without partition filter (to see if table works at all)
echo "Test 1: Querying table without filters..."
echo ""

QUERY1="SELECT COUNT(*) as total_rows FROM $DATABASE.health_data_raw LIMIT 1"

QUERY_ID1=$(aws athena start-query-execution \
    --query-string "$QUERY1" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID1"
echo "Waiting..."

sleep 10
STATUS1=$(aws athena get-query-execution \
    --query-execution-id "$QUERY_ID1" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS1" = "SUCCEEDED" ]; then
    RESULT1=$(aws athena get-query-results \
        --query-execution-id "$QUERY_ID1" \
        --region "$REGION" \
        --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
        --output text 2>/dev/null || echo "0")
    echo "  Total rows in table: $RESULT1"
else
    REASON1=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID1" \
        --region "$REGION" \
        --query 'QueryExecution.Status.StateChangeReason' \
        --output text 2>/dev/null || echo "Unknown")
    echo "  Status: $STATUS1 - $REASON1"
fi

echo ""

# Test 2: Query with tenant_id only
echo "Test 2: Querying with tenant_id filter..."
echo ""

QUERY2="SELECT COUNT(*) as rows 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID'
LIMIT 1"

QUERY_ID2=$(aws athena start-query-execution \
    --query-string "$QUERY2" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID2"
echo "Waiting..."

sleep 10
STATUS2=$(aws athena get-query-execution \
    --query-execution-id "$QUERY_ID2" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS2" = "SUCCEEDED" ]; then
    RESULT2=$(aws athena get-query-results \
        --query-execution-id "$QUERY_ID2" \
        --region "$REGION" \
        --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
        --output text 2>/dev/null || echo "0")
    echo "  Rows for tenant_id=$TENANT_ID: $RESULT2"
else
    REASON2=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID2" \
        --region "$REGION" \
        --query 'QueryExecution.Status.StateChangeReason' \
        --output text 2>/dev/null || echo "Unknown")
    echo "  Status: $STATUS2 - $REASON2"
fi

echo ""

# Test 3: Query with both filters
echo "Test 3: Querying with tenant_id and dt filters..."
echo ""

QUERY3="SELECT COUNT(*) as rows 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
  AND dt = '$DT'
LIMIT 1"

QUERY_ID3=$(aws athena start-query-execution \
    --query-string "$QUERY3" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID3"
echo "Waiting..."

sleep 10
STATUS3=$(aws athena get-query-execution \
    --query-execution-id "$QUERY_ID3" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS3" = "SUCCEEDED" ]; then
    RESULT3=$(aws athena get-query-results \
        --query-execution-id "$QUERY_ID3" \
        --region "$REGION" \
        --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
        --output text 2>/dev/null || echo "0")
    echo "  Rows for tenant_id=$TENANT_ID, dt=$DT: $RESULT3"
else
    REASON3=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID3" \
        --region "$REGION" \
        --query 'QueryExecution.Status.StateChangeReason' \
        --output text 2>/dev/null || echo "Unknown")
    echo "  Status: $STATUS3 - $REASON3"
fi

echo ""

# Test 4: Try to read actual data (first few rows)
echo "Test 4: Reading sample data..."
echo ""

QUERY4="SELECT * 
FROM $DATABASE.health_data_raw 
WHERE tenant_id = '$TENANT_ID' 
  AND dt = '$DT'
LIMIT 5"

QUERY_ID4=$(aws athena start-query-execution \
    --query-string "$QUERY4" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=s3://$BUCKET/athena-results/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID4"
echo "Waiting (this may take longer)..."

sleep 15
STATUS4=$(aws athena get-query-execution \
    --query-execution-id "$QUERY_ID4" \
    --region "$REGION" \
    --query 'QueryExecution.Status.State' \
    --output text 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS4" = "SUCCEEDED" ]; then
    echo "  ✅ Query succeeded! Sample data:"
    echo ""
    aws athena get-query-results \
        --query-execution-id "$QUERY_ID4" \
        --region "$REGION" \
        --query 'ResultSet.Rows[*].Data[*].VarCharValue' \
        --output table 2>/dev/null || echo "Could not format results"
else
    REASON4=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID4" \
        --region "$REGION" \
        --query 'QueryExecution.Status.StateChangeReason' \
        --output text 2>/dev/null || echo "Unknown")
    echo "  Status: $STATUS4"
    echo "  Reason: $REASON4"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "If all queries return 0 rows, possible issues:"
echo "1. Parquet schema doesn't match table schema"
echo "2. Files are empty"
echo "3. Partition columns (tenant_id/dt) are in the Parquet files (shouldn't be)"
echo ""
echo "Next step: Run check_parquet_schema.py to inspect actual file schema:"
echo "  cd ../backend"
echo "  source venv/bin/activate"
echo "  python3 ../athena/check_parquet_schema.py"
echo ""


