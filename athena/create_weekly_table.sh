#!/bin/bash
# Create just the gold_weekly_features table (fix for duplicate column)

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"

# Get tenant_id from argument or use default
TENANT_ID="${1:-rajasaikatukuri}"

echo "Creating gold_weekly_features table for tenant: $TENANT_ID"
echo ""

QUERY_ID=$(aws athena start-query-execution \
    --query-string "CREATE TABLE IF NOT EXISTS health_data_lake.gold_weekly_features
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by = ARRAY['tenant_id', 'week_start']
) AS
WITH weekly_data AS (
    SELECT
        DATE_FORMAT(DATE_ADD('day', -DAY_OF_WEEK(DATE_PARSE(dt, '%Y-%m-%d')) + 1, DATE_PARSE(dt, '%Y-%m-%d')), '%Y-%m-%d') as week_start,
        tenant_id,
        SUM(CASE WHEN data_type = 'stepCount' THEN value ELSE 0 END) as steps,
        SUM(CASE WHEN data_type = 'distanceWalkingRunning' THEN value ELSE 0 END) / 1000.0 as distance_km,
        SUM(CASE WHEN data_type = 'activeEnergyBurned' THEN value ELSE 0 END) as active_kcal,
        SUM(CASE WHEN data_type = 'basalEnergyBurned' THEN value ELSE 0 END) as basal_kcal,
        SUM(CASE WHEN data_type = 'flightsClimbed' THEN value ELSE 0 END) as flights,
        AVG(CASE WHEN data_type = 'heartRate' THEN value END) as hr_avg,
        MAX(CASE WHEN data_type = 'heartRate' THEN value END) as hr_max,
        MIN(CASE WHEN data_type = 'heartRate' THEN value END) as hr_min
    FROM health_data_lake.health_data_raw
    WHERE tenant_id = '${TENANT_ID}'
        AND dt >= DATE_FORMAT(DATE_ADD('day', -90, CURRENT_DATE), '%Y-%m-%d')
    GROUP BY 
        DATE_FORMAT(DATE_ADD('day', -DAY_OF_WEEK(DATE_PARSE(dt, '%Y-%m-%d')) + 1, DATE_PARSE(dt, '%Y-%m-%d')), '%Y-%m-%d'),
        tenant_id
)
SELECT
    COALESCE(steps, 0) as steps_week,
    COALESCE(distance_km, 0) as distance_km_week,
    COALESCE(active_kcal, 0) as active_kcal_week,
    COALESCE(basal_kcal, 0) as basal_kcal_week,
    COALESCE(flights, 0) as flights_week,
    COALESCE(hr_avg, 0) as hr_avg_week,
    COALESCE(hr_max, 0) as hr_max_week,
    COALESCE(hr_min, 0) as hr_min_week,
    tenant_id,
    week_start
FROM weekly_data" \
    --work-group "$WORKGROUP" \
    --region "$REGION" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting for completion..."

MAX_WAIT=300
ELAPSED=0
POLL_INTERVAL=5

while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text 2>/dev/null)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Query succeeded"
        exit 0
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "❌ Query failed"
        REASON=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text 2>/dev/null)
        echo "Reason: $REASON"
        exit 1
    fi
    
    echo "  Status: $STATUS (${ELAPSED}s)..."
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

echo "⚠️  Timeout"
exit 1

