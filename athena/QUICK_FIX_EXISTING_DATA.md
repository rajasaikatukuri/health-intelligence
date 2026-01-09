# Quick Fix: Connect Your Existing S3 Data

## Problem
You have data in S3, but Athena queries return NULL because:
- Partitions aren't registered
- Table location might not match your S3 path
- Gold tables need to be refreshed

## Quick Solution

Run this script to automatically:
1. Find your data in S3
2. Update table location if needed
3. Add partitions
4. Test data access
5. Refresh gold tables

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
./connect_existing_data.sh rajasaikatukuri
```

## Manual Steps (if script doesn't work)

### 1. Find Your Data Location

```bash
# List all files in your bucket
aws s3 ls s3://health-data-lake-640768199126-us-east-2/ --recursive | head -20

# Or check specific paths
aws s3 ls s3://health-data-lake-640768199126-us-east-2/health-data/raw/ --recursive
aws s3 ls s3://health-data-lake-640768199126-us-east-2/raw/ --recursive
```

### 2. Update Table Location (if needed)

If your data is in a different S3 path than expected:

```sql
-- Check current location
SHOW CREATE TABLE health_data_lake.health_data_raw;

-- Update location to match your S3 path
ALTER TABLE health_data_lake.health_data_raw 
SET LOCATION 's3://health-data-lake-640768199126-us-east-2/YOUR_ACTUAL_PATH/';
```

### 3. Add Partitions

If your data uses partition structure `tenant_id=xxx/dt=YYYY-MM-DD/`:

```sql
-- Option 1: Add partitions manually (one per date)
ALTER TABLE health_data_lake.health_data_raw 
ADD PARTITION (tenant_id='rajasaikatukuri', dt='2024-01-15');

ALTER TABLE health_data_lake.health_data_raw 
ADD PARTITION (tenant_id='rajasaikatukuri', dt='2024-01-16');
-- ... repeat for each date

-- Option 2: Use MSCK REPAIR (auto-discovers partitions)
MSCK REPAIR TABLE health_data_lake.health_data_raw;
```

### 4. Test Data Access

```sql
-- Check if data is accessible
SELECT COUNT(*) 
FROM health_data_lake.health_data_raw 
WHERE tenant_id = 'rajasaikatukuri';

-- Check sample data
SELECT * 
FROM health_data_lake.health_data_raw 
WHERE tenant_id = 'rajasaikatukuri' 
LIMIT 10;
```

### 5. Refresh Gold Tables

After confirming raw data is accessible:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
./create_gold_tables_for_tenant.sh rajasaikatukuri
```

## Common Issues

### Issue: "No partitions found"
**Solution**: Your data might not be partitioned. Check:
- S3 path structure matches `tenant_id=xxx/dt=YYYY-MM-DD/`
- Or update table to not use partitions

### Issue: "Table location doesn't match"
**Solution**: Update table location:
```sql
ALTER TABLE health_data_lake.health_data_raw 
SET LOCATION 's3://your-bucket/your-actual-path/';
```

### Issue: "Schema mismatch"
**Solution**: Check your Parquet file schema matches:
- `data_type` (string)
- `value` (double)
- `timestamp` (string)
- `timestamp_unix` (bigint)
- `unit` (string)
- `source_name` (string)
- `source_version` (string)
- `device` (string)
- `metadata` (string)

### Issue: "Data exists but queries return 0 rows"
**Solution**: 
1. Check tenant_id matches: `WHERE tenant_id = 'your-actual-tenant-id'`
2. Verify partitions are added
3. Check date format in `dt` partition matches your data

## Verify Everything Works

After connecting data:

```sql
-- 1. Raw data accessible?
SELECT COUNT(*) FROM health_data_lake.health_data_raw 
WHERE tenant_id = 'rajasaikatukuri';

-- 2. Silver view works?
SELECT COUNT(*) FROM health_data_lake.silver_health 
WHERE tenant_id = 'rajasaikatukuri';

-- 3. Gold tables populated?
SELECT COUNT(*) FROM health_data_lake.gold_daily_features 
WHERE tenant_id = 'rajasaikatukuri';
```

If all return > 0, you're good to go! Try your chat queries again.


