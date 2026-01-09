#!/bin/bash
# Setup Athena tables for Health Intelligence Platform

set -e

REGION="us-east-2"
DATABASE="health_data_lake"
WORKGROUP="health-data-tenant-queries"
BUCKET="health-data-lake-640768199126-us-east-2"

echo "=========================================="
echo "Setting up Athena Tables"
echo "=========================================="
echo ""

# Function to execute Athena query
execute_athena_query() {
    local query="$1"
    local description="$2"
    
    echo "📊 $description..."
    echo "Query: $query"
    echo ""
    
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --work-group "$WORKGROUP" \
        --region "$REGION" \
        --query 'QueryExecutionId' \
        --output text)
    
    echo "Query ID: $QUERY_ID"
    echo "Waiting for completion..."
    echo "You can check status manually: aws athena get-query-execution --query-execution-id $QUERY_ID --region $REGION"
    
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
            echo "✅ Query succeeded"
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            echo "❌ Query failed or cancelled"
            REASON=$(aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text 2>/dev/null)
            echo "Reason: $REASON"
            exit 1
        elif [ "$STATUS" = "RUNNING" ] || [ "$STATUS" = "QUEUED" ]; then
            echo "  Status: $STATUS (${ELAPSED}s elapsed)..."
        else
            echo "  Status: $STATUS"
        fi
        
        sleep $POLL_INTERVAL
        ELAPSED=$((ELAPSED + POLL_INTERVAL))
    done
    
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo "⚠️  Query timeout after ${MAX_WAIT}s"
        echo "Query is still running. Check status manually:"
        echo "  aws athena get-query-execution --query-execution-id $QUERY_ID --region $REGION"
        echo ""
        echo "You can continue with next steps or wait for this query to complete."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo ""
}

# Step 1: Create raw table (if not exists)
echo "Step 1: Creating raw table..."
RAW_TABLE_DDL=$(cat <<'EOF'
CREATE EXTERNAL TABLE IF NOT EXISTS health_data_lake.health_data_raw (
    data_type string,
    value double,
    timestamp string,
    timestamp_unix bigint,
    unit string,
    source_name string,
    source_version string,
    device string,
    metadata string
)
PARTITIONED BY (
    tenant_id string,
    dt string
)
STORED AS PARQUET
LOCATION 's3://health-data-lake-640768199126-us-east-2/health-data/raw/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.tenant_id.type' = 'injected',
    'projection.dt.type' = 'date',
    'projection.dt.format' = 'yyyy-MM-dd',
    'projection.dt.range' = '2024-01-01,NOW',
    'projection.dt.interval' = '1',
    'projection.dt.interval.unit' = 'DAYS',
    'storage.location.template' = 's3://health-data-lake-640768199126-us-east-2/health-data/raw/tenant_id=${tenant_id}/dt=${dt}'
)
EOF
)
execute_athena_query "$RAW_TABLE_DDL" "Creating raw table"

# Step 2: Create silver view
echo "Step 2: Creating silver view..."
SILVER_VIEW_DDL=$(cat <<'EOF'
CREATE OR REPLACE VIEW health_data_lake.silver_health AS
SELECT
    tenant_id,
    dt as day,
    DATE_FORMAT(DATE_PARSE(dt, '%Y-%m-%d'), '%Y-%m-%d') as date_parsed,
    DATE_FORMAT(DATE_ADD('day', -DAY_OF_WEEK(DATE_PARSE(dt, '%Y-%m-%d')) + 1, DATE_PARSE(dt, '%Y-%m-%d')), '%Y-%m-%d') as week_start,
    data_type,
    value,
    CAST(timestamp_unix AS BIGINT) as timestamp_unix,
    timestamp,
    unit,
    source_name,
    source_version,
    device,
    metadata
FROM health_data_lake.health_data_raw
WHERE tenant_id = '${tenant_id}'
EOF
)
execute_athena_query "$SILVER_VIEW_DDL" "Creating silver view"

# Step 3: Create gold_daily_by_type table
echo "Step 3: Creating gold_daily_by_type table..."
GOLD_DAILY_TYPE_CTAS=$(cat <<'EOF'
CREATE TABLE IF NOT EXISTS health_data_lake.gold_daily_by_type
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by = ARRAY['tenant_id', 'dt'],
    external_location = 's3://health-data-lake-640768199126-us-east-2/health-data/gold/daily_by_type/'
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
WHERE tenant_id = '${tenant_id}'
    AND dt >= DATE_FORMAT(DATE_ADD('day', -90, CURRENT_DATE), '%Y-%m-%d')
GROUP BY dt, data_type, tenant_id
EOF
)
execute_athena_query "$GOLD_DAILY_TYPE_CTAS" "Creating gold_daily_by_type table"

# Step 4: Create gold_daily_features table
echo "Step 4: Creating gold_daily_features table..."
GOLD_DAILY_FEATURES_CTAS=$(cat <<'EOF'
CREATE TABLE IF NOT EXISTS health_data_lake.gold_daily_features
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by = ARRAY['tenant_id', 'dt'],
    external_location = 's3://health-data-lake-640768199126-us-east-2/health-data/gold/daily_features/'
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
WHERE tenant_id = '${tenant_id}'
    AND dt >= DATE_FORMAT(DATE_ADD('day', -90, CURRENT_DATE), '%Y-%m-%d')
GROUP BY dt, tenant_id
EOF
)
execute_athena_query "$GOLD_DAILY_FEATURES_CTAS" "Creating gold_daily_features table"

# Step 5: Create gold_weekly_features table
echo "Step 5: Creating gold_weekly_features table..."
GOLD_WEEKLY_FEATURES_CTAS=$(cat <<'EOF'
CREATE TABLE IF NOT EXISTS health_data_lake.gold_weekly_features
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by = ARRAY['tenant_id', 'week_start'],
    external_location = 's3://health-data-lake-640768199126-us-east-2/health-data/gold/weekly_features/'
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
    WHERE tenant_id = '${tenant_id}'
        AND dt >= DATE_FORMAT(DATE_ADD('day', -90, CURRENT_DATE), '%Y-%m-%d')
    GROUP BY 
        DATE_FORMAT(DATE_ADD('day', -DAY_OF_WEEK(DATE_PARSE(dt, '%Y-%m-%d')) + 1, DATE_PARSE(dt, '%Y-%m-%d')), '%Y-%m-%d'),
        tenant_id
)
SELECT
    week_start,
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
echo "✅ All tables created successfully!"
echo "=========================================="
echo ""
echo "Tables created:"
echo "  - health_data_lake.health_data_raw (external)"
echo "  - health_data_lake.silver_health (view)"
echo "  - health_data_lake.gold_daily_by_type (CTAS)"
echo "  - health_data_lake.gold_daily_features (CTAS)"
echo "  - health_data_lake.gold_weekly_features (CTAS)"
echo ""
echo "Note: Gold tables are partitioned. To refresh data, run:"
echo "  ./refresh_gold_tables.sh"

