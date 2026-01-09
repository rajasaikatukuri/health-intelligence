# Diagnosing "No Data" Issue

## Problem
Your queries are executing successfully, but returning NULL values. This means:
- ✅ Tables are created correctly
- ✅ SQL queries are working
- ❌ **No data exists in the tables**

## Quick Diagnosis

Run this command to check for data:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend
source venv/bin/activate
python3 check_data.py
```

## Solution Options

### Option 1: Generate Sample Data (Quick Test)

Generate sample health data for testing:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend
source venv/bin/activate
python3 generate_sample_data.py rajasaikatukuri 30
```

This will:
- Create 30 days of sample data
- Upload Parquet files to S3
- Match the expected schema

**After generating data:**
1. Wait 1-2 minutes for S3/Athena to recognize new files
2. Refresh gold tables:
   ```bash
   cd ../athena
   ./create_gold_tables_for_tenant.sh rajasaikatukuri
   ```
3. Try your queries again!

### Option 2: Use Real Data from iOS App

If you have the iOS app set up:

1. **Make sure the iOS app is configured:**
   - Backend URL is correct
   - JWT token is valid
   - HealthKit permissions are granted

2. **Sync data from iOS app:**
   - Open the iOS app
   - Tap "Sync Health Data"
   - Wait for upload to complete

3. **Verify data in S3:**
   ```bash
   aws s3 ls s3://health-data-lake-640768199126-us-east-2/health-data/raw/tenant_id=rajasaikatukuri/ --recursive
   ```

4. **Refresh Athena partitions** (if not using partition projection):
   ```sql
   ALTER TABLE health_data_lake.health_data_raw ADD PARTITION 
   (tenant_id='rajasaikatukuri', dt='2024-01-15');
   ```

5. **Refresh gold tables:**
   ```bash
   cd athena
   ./create_gold_tables_for_tenant.sh rajasaikatukuri
   ```

### Option 3: Manual Data Upload

If you have Parquet files:

1. Upload to S3 with this structure:
   ```
   s3://bucket/health-data/raw/tenant_id=rajasaikatukuri/dt=2024-01-15/data.parquet
   ```

2. Ensure Parquet schema matches:
   - `data_type` (string)
   - `value` (double)
   - `timestamp` (string)
   - `timestamp_unix` (bigint)
   - `unit` (string)
   - `source_name` (string)
   - `source_version` (string)
   - `device` (string)
   - `metadata` (string)

3. Refresh partitions and gold tables as above.

## Expected Data Flow

```
iOS App → API Gateway → Lambda → S3 (raw) → Athena (silver) → Athena (gold) → Chat Interface
```

If any step is missing, data won't appear in queries.

## Verification

After adding data, verify with:

```sql
-- Check raw data
SELECT COUNT(*) 
FROM health_data_lake.health_data_raw 
WHERE tenant_id = 'rajasaikatukuri';

-- Check silver view
SELECT COUNT(*) 
FROM health_data_lake.silver_health 
WHERE tenant_id = 'rajasaikatukuri';

-- Check gold tables
SELECT COUNT(*) 
FROM health_data_lake.gold_daily_features 
WHERE tenant_id = 'rajasaikatukuri';
```

## Common Issues

1. **Partitions not recognized**: Wait 1-2 minutes or run `MSCK REPAIR TABLE`
2. **Wrong S3 path**: Check `setup_tables_simple.sh` for expected location
3. **Schema mismatch**: Ensure Parquet files match table schema
4. **Gold tables empty**: Run `create_gold_tables_for_tenant.sh` after adding raw data


