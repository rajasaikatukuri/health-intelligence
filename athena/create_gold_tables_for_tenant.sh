#!/bin/bash
# Create gold tables for a specific tenant
# This works around partition projection requirements

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"

# Get tenant_id from argument or use default
TENANT_ID="${1:-rajasaikatukuri}"

echo "=========================================="
echo "Creating Gold Tables for Tenant: $TENANT_ID"
echo "=========================================="
echo ""

# Function to execute Athena query
execute_athena_query() {
    local query="$1"
    local description="$2"
    
    echo "📊 $description..."
    
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --work-group "$WORKGROUP" \
        --region "$REGION" \
        --query 'QueryExecutionId' \
        --output text)
    
    echo "  Query ID: $QUERY_ID"
    echo "  Waiting for completion (this may take 1-3 minutes)..."
    
    # Poll for completion with timeout
    MAX_WAIT=300  # 5 minutes max wait
    ELAPSED=0
    POLL_INTERVAL=5
    
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        STATUS=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.Status.State' \
            --output text 2>/dev/null)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "  ✅ Query succeeded"
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            echo "  ❌ Query failed or cancelled"
            REASON=$(aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text 2>/dev/null)
            echo "  Reason: $REASON"
            return 1
        elif [ "$STATUS" = "RUNNING" ] || [ "$STATUS" = "QUEUED" ]; then
            echo "  Status: $STATUS (${ELAPSED}s elapsed)..."
        fi
        
        sleep $POLL_INTERVAL
        ELAPSED=$((ELAPSED + POLL_INTERVAL))
    done
    
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo "  ⚠️  Query timeout after ${MAX_WAIT}s"
        echo "  Check status: aws athena get-query-execution --query-execution-id $QUERY_ID --region $REGION"
        return 1
    fi
    
    echo ""
    return 0
}

# Step 1: Create gold_daily_by_type table
echo "Step 1: Creating gold_daily_by_type table..."
GOLD_DAILY_TYPE_CTAS=$(cat <<EOF
CREATE TABLE IF NOT EXISTS health_data_lake.gold_daily_by_type
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by = ARRAY['tenant_id', 'dt']
) AS
SELECT
    dt as day,
    data_type,
    COUNT(*) as samples,
    SUM(value) as sum_value,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    tenant_id,
    dt
FROM health_data_lake.health_data_raw
WHERE tenant_id = '${TENANT_ID}'
    AND dt >= DATE_FORMAT(DATE_ADD('day', -90, CURRENT_DATE), '%Y-%m-%d')
GROUP BY dt, data_type, tenant_id
EOF
)
execute_athena_query "$GOLD_DAILY_TYPE_CTAS" "Creating gold_daily_by_type table"

# Step 2: Create gold_daily_features table
echo "Step 2: Creating gold_daily_features table..."
GOLD_DAILY_FEATURES_CTAS=$(cat <<EOF
CREATE TABLE IF NOT EXISTS health_data_lake.gold_daily_features
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by = ARRAY['tenant_id', 'dt']
) AS
SELECT
    dt as day,
    COALESCE(SUM(CASE WHEN data_type = 'stepCount' THEN value ELSE 0 END), 0) as steps_total,
    COALESCE(SUM(CASE WHEN data_type = 'distanceWalkingRunning' THEN value ELSE 0 END) / 1000.0, 0) as distance_km_total,
    COALESCE(SUM(CASE WHEN data_type = 'activeEnergyBurned' THEN value ELSE 0 END), 0) as active_kcal_total,
    COALESCE(SUM(CASE WHEN data_type = 'basalEnergyBurned' THEN value ELSE 0 END), 0) as basal_kcal_total,
    COALESCE(SUM(CASE WHEN data_type = 'flightsClimbed' THEN value ELSE 0 END), 0) as flights_total,
    COALESCE(AVG(CASE WHEN data_type = 'heartRate' THEN value END), 0) as hr_avg,
    COALESCE(MAX(CASE WHEN data_type = 'heartRate' THEN value END), 0) as hr_max,
    COALESCE(MIN(CASE WHEN data_type = 'heartRate' THEN value END), 0) as hr_min,
    tenant_id,
    dt
FROM health_data_lake.health_data_raw
WHERE tenant_id = '${TENANT_ID}'
    AND dt >= DATE_FORMAT(DATE_ADD('day', -90, CURRENT_DATE), '%Y-%m-%d')
GROUP BY dt, tenant_id
EOF
)
execute_athena_query "$GOLD_DAILY_FEATURES_CTAS" "Creating gold_daily_features table"

# Step 3: Create gold_weekly_features table
echo "Step 3: Creating gold_weekly_features table..."
GOLD_WEEKLY_FEATURES_CTAS=$(cat <<EOF
CREATE TABLE IF NOT EXISTS health_data_lake.gold_weekly_features
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
FROM weekly_data
EOF
)
execute_athena_query "$GOLD_WEEKLY_FEATURES_CTAS" "Creating gold_weekly_features table"

echo ""
echo "=========================================="
echo "✅ Gold tables created successfully!"
echo "=========================================="
echo ""
echo "Tables created for tenant: $TENANT_ID"
echo "  - health_data_lake.gold_daily_by_type"
echo "  - health_data_lake.gold_daily_features"
echo "  - health_data_lake.gold_weekly_features"
echo ""
echo "You can now try your questions again in the frontend!"
echo ""

