#!/bin/bash
# Refresh gold tables with latest data

set -e

REGION="us-east-2"
WORKGROUP="health-data-tenant-queries"

echo "=========================================="
echo "Refreshing Gold Tables"
echo "=========================================="
echo ""
echo "⚠️  This will recreate gold tables with latest data"
echo "    This may take several minutes..."
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Function to execute CTAS query
execute_ctas() {
    local query="$1"
    local description="$2"
    
    echo "📊 $description..."
    
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --work-group "$WORKGROUP" \
        --region "$REGION" \
        --query 'QueryExecutionId' \
        --output text)
    
    echo "Query ID: $QUERY_ID"
    echo "Waiting for completion (this may take a few minutes)..."
    
    while true; do
        STATUS=$(aws athena get-query-execution \
            --query-execution-id "$QUERY_ID" \
            --region "$REGION" \
            --query 'QueryExecution.State' \
            --output text)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "✅ Query succeeded"
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            echo "❌ Query failed or cancelled"
            aws athena get-query-execution \
                --query-execution-id "$QUERY_ID" \
                --region "$REGION" \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text
            exit 1
        fi
        
        sleep 5
    done
    
    echo ""
}

# Note: These queries use tenant_id placeholder
# In production, replace ${tenant_id} with actual tenant_id or use parameterized queries

echo "⚠️  Note: These queries use tenant_id placeholder."
echo "    For single-tenant refresh, replace \${tenant_id} with your tenant_id"
echo ""

# Refresh gold_daily_by_type
GOLD_DAILY_TYPE_CTAS=$(cat <<'EOF'
INSERT INTO health_data_lake.gold_daily_by_type
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
    AND (dt, data_type, tenant_id) NOT IN (
        SELECT day, data_type, tenant_id FROM health_data_lake.gold_daily_by_type
    )
GROUP BY dt, data_type, tenant_id
EOF
)

# Refresh gold_daily_features
GOLD_DAILY_FEATURES_CTAS=$(cat <<'EOF'
INSERT INTO health_data_lake.gold_daily_features
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
    AND (dt, tenant_id) NOT IN (
        SELECT day, tenant_id FROM health_data_lake.gold_daily_features
    )
GROUP BY dt, tenant_id
EOF
)

echo "For incremental refresh, use INSERT statements above."
echo "For full refresh, drop and recreate tables using setup_tables.sh"






