# Finding Your Data in S3

The script didn't find data in expected locations. Let's discover where it actually is.

## Quick Discovery

Run this to find all your data:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
chmod +x find_my_data.sh
./find_my_data.sh
```

## Manual Discovery

If the script doesn't work, try these commands:

### 1. List All Files in Bucket

```bash
aws s3 ls s3://health-data-lake-640768199126-us-east-2/ --recursive | head -50
```

### 2. List Top-Level Directories

```bash
aws s3 ls s3://health-data-lake-640768199126-us-east-2/
```

### 3. Search for Parquet Files

```bash
aws s3 ls s3://health-data-lake-640768199126-us-east-2/ --recursive | grep -i parquet
```

### 4. Check Different Bucket Names

Maybe your data is in a different bucket:

```bash
# List all your buckets
aws s3 ls

# Then check each one
aws s3 ls s3://OTHER-BUCKET-NAME/ --recursive | head -20
```

## Once You Find Your Data

### Option A: Data is in Different Path

If your data is at `s3://bucket/some/other/path/`:

1. **Update table location:**
   ```sql
   ALTER TABLE health_data_lake.health_data_raw 
   SET LOCATION 's3://health-data-lake-640768199126-us-east-2/some/other/path/';
   ```

2. **Add partitions** (if partitioned):
   ```sql
   ALTER TABLE health_data_lake.health_data_raw 
   ADD PARTITION (tenant_id='rajasaikatukuri', dt='2024-01-15');
   ```

3. **Or use MSCK REPAIR** (auto-discovers partitions):
   ```sql
   MSCK REPAIR TABLE health_data_lake.health_data_raw;
   ```

### Option B: Data is in Different Bucket

1. **Update table location:**
   ```sql
   ALTER TABLE health_data_lake.health_data_raw 
   SET LOCATION 's3://YOUR-ACTUAL-BUCKET/path/to/data/';
   ```

2. **Update config** in `backend/config.py`:
   ```python
   s3_bucket = "YOUR-ACTUAL-BUCKET"
   ```

### Option C: Data is Not Partitioned

If your data is flat (not in `tenant_id=xxx/dt=YYYY-MM-DD/` structure):

1. **Recreate table without partitions:**
   ```sql
   DROP TABLE IF EXISTS health_data_lake.health_data_raw;
   
   CREATE EXTERNAL TABLE health_data_lake.health_data_raw (
       data_type string,
       value double,
       timestamp string,
       timestamp_unix bigint,
       unit string,
       source_name string,
       source_version string,
       device string,
       metadata string,
       tenant_id string,  -- Now a regular column
       dt string          -- Now a regular column
   )
   STORED AS PARQUET
   LOCATION 's3://your-bucket/your-path/';
   ```

2. **Update queries** to filter by `tenant_id` as a column, not partition

### Option D: Data Format is Different

If your Parquet files have different schema:

1. **Check schema:**
   ```python
   import pyarrow.parquet as pq
   table = pq.read_table('s3://bucket/path/file.parquet')
   print(table.schema)
   ```

2. **Update table DDL** to match your actual schema

## Common Scenarios

### Scenario 1: Data in Different AWS Account/Region

Check your AWS credentials and region:
```bash
aws configure list
aws sts get-caller-identity
```

### Scenario 2: Data is JSON, not Parquet

If your data is JSON:
1. Convert to Parquet, OR
2. Create table with `ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'`

### Scenario 3: Data Exists But Permissions Issue

Check IAM permissions:
```bash
aws s3api head-bucket --bucket health-data-lake-640768199126-us-east-2
```

## After Finding Data

Once you know where your data is:

1. **Update table location** (if needed)
2. **Add partitions** (if partitioned)
3. **Test query:**
   ```sql
   SELECT COUNT(*) FROM health_data_lake.health_data_raw 
   WHERE tenant_id = 'rajasaikatukuri';
   ```
4. **Refresh gold tables:**
   ```bash
   ./create_gold_tables_for_tenant.sh rajasaikatukuri
   ```

## Still Can't Find It?

Share the output of:
```bash
aws s3 ls s3://health-data-lake-640768199126-us-east-2/ --recursive | head -30
```

And I'll help you figure out the exact path structure!


