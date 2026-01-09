# 🔧 Fix: Athena Tables Don't Exist

## Problem
```
Error: TABLE_NOT_FOUND: Table 'awsdatacatalog.health_data_lake.gold_daily_features' does not exist
```

The gold tables haven't been created in Athena yet.

---

## Quick Fix: Create Gold Tables

Run this script:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
./create_gold_tables.sh
```

This will create:
- `gold_daily_by_type` - Daily aggregations by data type
- `gold_daily_features` - Daily health features (steps, heart rate, etc.)
- `gold_weekly_features` - Weekly health features

**Time:** Each table takes 1-3 minutes to create.

---

## What This Does

The script:
1. Creates CTAS (Create Table As Select) queries
2. Processes the last 90 days of data from `health_data_raw`
3. Aggregates data into daily/weekly summaries
4. Stores results in S3 as Parquet files
5. Creates partitioned tables for fast queries

---

## After Tables Are Created

1. Wait for the script to finish (you'll see "✅ Gold tables created successfully!")
2. Go back to your browser at http://localhost:3000
3. Try your question again: **"Summarize my last 30 days"**

It should work now! 🎉

---

## Verify Tables Exist

```bash
aws athena list-table-metadata \
  --catalog-name AwsDataCatalog \
  --database-name health_data_lake \
  --region us-east-2 \
  --query 'TableMetadataList[?contains(TableName, `gold`)].TableName' \
  --output table
```

Should show:
- `gold_daily_by_type`
- `gold_daily_features`
- `gold_weekly_features`

---

## Troubleshooting

**If the script fails:**
- Check that `health_data_raw` table exists
- Verify you have data in S3
- Check AWS credentials are configured

**If queries are slow:**
- The gold tables are partitioned by `tenant_id` and `dt`
- Queries should automatically filter to your tenant
- First query may be slower (cold start)

---

## Next Steps

After creating the tables, you can:
1. Ask questions in the chat interface
2. Generate dashboards
3. Compare time periods
4. Detect anomalies

The gold tables make queries much faster than querying raw data directly!




