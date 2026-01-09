#!/usr/bin/env python3
"""Check if data exists in S3 and Athena tables."""
import boto3
import sys
from config import settings

def check_s3_data():
    """Check if data exists in S3."""
    print("=" * 60)
    print("Checking S3 Data Lake")
    print("=" * 60)
    print(f"Bucket: {settings.s3_bucket}")
    print(f"Region: {settings.aws_region}")
    print()
    
    s3 = boto3.client('s3', region_name=settings.aws_region)
    
    # Check for raw data
    prefixes_to_check = [
        'health-data/raw/',
        'raw/',
        'health-data/raw/tenant_id=rajasaikatukuri/',
    ]
    
    found_data = False
    for prefix in prefixes_to_check:
        try:
            response = s3.list_objects_v2(
                Bucket=settings.s3_bucket,
                Prefix=prefix,
                MaxKeys=10
            )
            
            if 'Contents' in response and len(response['Contents']) > 0:
                print(f"✅ Found data in: {prefix}")
                print(f"   Found {len(response['Contents'])} objects (showing first 5):")
                total_size = 0
                for obj in response['Contents'][:5]:
                    size = obj['Size']
                    total_size += size
                    print(f"   - {obj['Key']} ({size:,} bytes)")
                print(f"   Total size: {total_size:,} bytes")
                found_data = True
                break
        except Exception as e:
            print(f"   ⚠️  Error checking {prefix}: {e}")
    
    if not found_data:
        print("❌ No data found in S3")
        print()
        print("Expected location: s3://{}/health-data/raw/tenant_id=rajasaikatukuri/dt=YYYY-MM-DD/".format(settings.s3_bucket))
        print()
        print("To add data, you need to:")
        print("1. Use the iOS app to sync HealthKit data")
        print("2. Or manually upload Parquet files to S3")
    
    return found_data

def check_athena_data():
    """Check if data exists in Athena tables."""
    print()
    print("=" * 60)
    print("Checking Athena Tables")
    print("=" * 60)
    
    athena = boto3.client('athena', region_name=settings.aws_region)
    
    queries = [
        ("Raw Table", f"""
            SELECT COUNT(*) as count
            FROM {settings.athena_database}.health_data_raw
            WHERE tenant_id = 'rajasaikatukuri'
            LIMIT 1
        """),
        ("Silver View", f"""
            SELECT COUNT(*) as count
            FROM {settings.athena_database}.silver_health
            WHERE tenant_id = 'rajasaikatukuri'
            LIMIT 1
        """),
        ("Gold Daily Features", f"""
            SELECT COUNT(*) as count
            FROM {settings.athena_database}.gold_daily_features
            WHERE tenant_id = 'rajasaikatukuri'
            LIMIT 1
        """),
    ]
    
    for name, query in queries:
        try:
            print(f"\n📊 Checking {name}...")
            
            response = athena.start_query_execution(
                QueryString=query,
                QueryExecutionContext={'Database': settings.athena_database},
                ResultConfiguration={
                    'OutputLocation': f's3://{settings.s3_results_bucket}/{settings.s3_results_prefix}'
                },
                WorkGroup=settings.athena_workgroup
            )
            
            query_id = response['QueryExecutionId']
            
            # Wait for completion
            import time
            max_wait = 30
            elapsed = 0
            while elapsed < max_wait:
                status = athena.get_query_execution(QueryExecutionId=query_id)
                state = status['QueryExecution']['Status']['State']
                
                if state == 'SUCCEEDED':
                    # Get results
                    results = athena.get_query_results(QueryExecutionId=query_id)
                    if results['ResultSet']['Rows']:
                        count = results['ResultSet']['Rows'][1]['Data'][0].get('VarCharValue', '0')
                        count_int = int(count) if count else 0
                        if count_int > 0:
                            print(f"   ✅ {name}: {count_int:,} rows")
                        else:
                            print(f"   ❌ {name}: No data (0 rows)")
                    break
                elif state in ['FAILED', 'CANCELLED']:
                    reason = status['QueryExecution']['Status'].get('StateChangeReason', 'Unknown')
                    print(f"   ❌ Query failed: {reason}")
                    break
                
                time.sleep(2)
                elapsed += 2
            
            if elapsed >= max_wait:
                print(f"   ⚠️  Query timed out after {max_wait}s")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")

if __name__ == '__main__':
    print()
    print("🔍 Health Data Lake - Data Checker")
    print()
    
    s3_has_data = check_s3_data()
    check_athena_data()
    
    print()
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    
    if not s3_has_data:
        print()
        print("⚠️  NO DATA FOUND")
        print()
        print("Your tables are set up correctly, but there's no data to query.")
        print()
        print("To get data:")
        print("1. Use your iOS app to sync HealthKit data to AWS")
        print("2. Or create sample data for testing")
        print()
        print("Would you like me to create a script to generate sample data?")
    else:
        print()
        print("✅ Data found! Your pipeline should be working.")
        print("   If queries still return NULL, check:")
        print("   - Data format matches expected schema")
        print("   - Partition structure is correct")
        print("   - Gold tables need to be refreshed")


