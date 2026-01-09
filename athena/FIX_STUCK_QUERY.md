# Fix: Stuck Athena Query

Your query has been running for 3 hours. Here's how to fix it.

---

## Step 1: Check Query Status

Run this in your terminal:

```bash
aws athena get-query-execution \
  --query-execution-id 45d5c04e-0057-45a5-a04b-c6abf6963103 \
  --region us-east-2 \
  --query 'QueryExecution.Status' \
  --output json
```

**Or use the helper script:**
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
./check_query.sh 45d5c04e-0057-45a5-a04b-c6abf6963103
```

---

## Step 2: Options

### Option A: Query Already Succeeded (Most Likely)

The table might already be created! Check:

```bash
aws athena list-table-metadata \
  --catalog-name AwsDataCatalog \
  --database-name health_data_lake \
  --region us-east-2
```

If you see `health_data_raw`, the table exists! You can:
1. **Cancel the stuck script** (Ctrl+C)
2. **Skip to Step 2** (create silver view)

### Option B: Cancel and Retry

If the query is still running and you want to cancel:

```bash
aws athena stop-query-execution \
  --query-execution-id 45d5c04e-0057-45a5-a04b-c6abf6963103 \
  --region us-east-2
```

Then check if table exists, or retry with a simpler approach.

### Option C: Use Simpler DDL (No Partition Projection)

The partition projection might be causing issues. Try creating the table without it:

```bash
aws athena start-query-execution \
  --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS health_data_lake.health_data_raw (
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
LOCATION 's3://health-data-lake-640768199126-us-east-2/health-data/raw/'" \
  --work-group health-data-tenant-queries \
  --region us-east-2
```

---

## Step 3: Skip and Continue

If the table already exists, you can skip to creating the silver view:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena

# Create a modified script that skips Step 1
# Or manually run just the silver view creation
```

---

## Quick Fix: Check and Continue

Run these commands:

```bash
# 1. Check if table exists
aws athena list-table-metadata \
  --catalog-name AwsDataCatalog \
  --database-name health_data_lake \
  --region us-east-2 | grep health_data_raw

# 2. If table exists, cancel the script (Ctrl+C) and continue manually
# 3. If table doesn't exist, cancel query and retry with simpler DDL
```

---

## Updated Script

I've updated `setup_tables.sh` with:
- ✅ Timeout (5 minutes max wait)
- ✅ Better status reporting
- ✅ Option to continue if timeout

**The updated script will:**
- Show progress every 5 seconds
- Timeout after 5 minutes
- Ask if you want to continue

---

**Run the check_query.sh script first to see the actual status!**





