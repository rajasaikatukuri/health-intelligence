#!/usr/bin/env python3
"""
Check the actual schema of Parquet files in S3 and compare with table schema.
"""
import boto3
import pyarrow.parquet as pq
from io import BytesIO
import sys

BUCKET = "health-data-lake-640768199126-us-east-2"
REGION = "us-east-2"
TENANT_ID = "rajasaikatukuri"
DT = "2026-01-04"

print("=" * 60)
print("Checking Parquet File Schema")
print("=" * 60)
print()
print(f"Bucket: {BUCKET}")
print(f"Path: health-data/raw/tenant_id={TENANT_ID}/dt={DT}/")
print()

s3 = boto3.client('s3', region_name=REGION)

# List Parquet files
prefix = f"health-data/raw/tenant_id={TENANT_ID}/dt={DT}/"
print("Step 1: Finding Parquet files...")
print()

try:
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)
    
    if 'Contents' not in response:
        print("❌ No files found!")
        sys.exit(1)
    
    parquet_files = [obj['Key'] for obj in response['Contents'] if obj['Key'].endswith('.parquet')]
    
    print(f"✅ Found {len(parquet_files)} Parquet files")
    print()
    
    if not parquet_files:
        print("❌ No Parquet files found!")
        sys.exit(1)
    
    # Read first file to check schema
    first_file = parquet_files[0]
    print(f"Step 2: Reading schema from: {first_file}")
    print()
    
    # Download and read Parquet file
    obj = s3.get_object(Bucket=BUCKET, Key=first_file)
    parquet_file = BytesIO(obj['Body'].read())
    
    table = pq.read_table(parquet_file)
    schema = table.schema
    
    print("Actual Parquet Schema:")
    print("-" * 60)
    for i, field in enumerate(schema):
        print(f"  {i+1}. {field.name}: {field.type}")
    print()
    
    # Expected schema
    print("Expected Table Schema:")
    print("-" * 60)
    expected_fields = [
        ("data_type", "string"),
        ("value", "double"),
        ("timestamp", "string"),
        ("timestamp_unix", "bigint"),
        ("unit", "string"),
        ("source_name", "string"),
        ("source_version", "string"),
        ("device", "string"),
        ("metadata", "string"),
    ]
    
    for name, dtype in expected_fields:
        print(f"  - {name}: {dtype}")
    print()
    
    # Check for tenant_id and dt columns
    print("Step 3: Checking for partition columns...")
    print()
    
    field_names = [field.name for field in schema]
    
    has_tenant_id = 'tenant_id' in field_names
    has_dt = 'dt' in field_names
    
    print(f"  tenant_id column in file: {'✅' if has_tenant_id else '❌'}")
    print(f"  dt column in file: {'✅' if has_dt else '❌'}")
    print()
    
    if has_tenant_id or has_dt:
        print("⚠️  WARNING: Parquet files contain partition columns!")
        print("   Partition columns should NOT be in the Parquet files.")
        print("   They are inferred from the S3 path structure.")
        print()
    
    # Check sample data
    print("Step 4: Checking sample data...")
    print()
    
    df = table.to_pandas()
    print(f"  Rows in file: {len(df)}")
    print()
    
    if len(df) > 0:
        print("  Sample data (first 3 rows):")
        print()
        print(df.head(3).to_string())
        print()
        
        # Check data types
        print("  Column data types:")
        for col, dtype in df.dtypes.items():
            print(f"    {col}: {dtype}")
        print()
    else:
        print("  ⚠️  File is empty!")
        print()
    
    # Schema comparison
    print("Step 5: Schema Comparison")
    print("-" * 60)
    print()
    
    mismatches = []
    for name, expected_type in expected_fields:
        if name not in field_names:
            mismatches.append(f"Missing column: {name}")
        else:
            # Type checking is approximate
            actual_field = next(f for f in schema if f.name == name)
            print(f"  ✅ {name}: {actual_field.type}")
    
    for field in schema:
        if field.name not in [f[0] for f in expected_fields] and field.name not in ['tenant_id', 'dt']:
            mismatches.append(f"Unexpected column: {field.name} ({field.type})")
    
    if mismatches:
        print()
        print("⚠️  Schema Issues:")
        for issue in mismatches:
            print(f"  - {issue}")
    else:
        print()
        print("✅ Schema matches expected structure!")
    
    print()
    print("=" * 60)
    print("Recommendations")
    print("=" * 60)
    print()
    
    if has_tenant_id or has_dt:
        print("1. Your Parquet files include partition columns.")
        print("   Solution: Either remove tenant_id/dt from files, OR")
        print("   update table to include them as regular columns (not partitions)")
        print()
    
    if len(df) == 0:
        print("1. Files are empty - check your data ingestion process")
        print()
    elif len(mismatches) > 0:
        print("1. Schema mismatch detected - update table DDL to match actual schema")
        print()
    else:
        print("✅ Schema looks good! The issue might be:")
        print("   1. Wait 1-2 minutes for Athena to recognize new partition")
        print("   2. Try querying without partition filter first")
        print("   3. Check if files are actually readable")
        print()
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)



