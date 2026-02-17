#!/usr/bin/env python3
"""
Generate sample health data for testing the Health Intelligence Platform.

This script creates sample Parquet files in S3 that match the expected schema.
"""
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime, timedelta
from io import BytesIO
import random
from config import settings

def generate_sample_data(tenant_id: str, days: int = 30):
    """Generate sample health data for the last N days."""
    print(f"Generating sample data for tenant: {tenant_id}")
    print(f"Generating {days} days of data...")
    print()
    
    s3 = boto3.client('s3', region_name=settings.aws_region)
    
    # Data types we'll generate
    data_types = {
        'stepCount': {'unit': 'count', 'base_value': 8000, 'variance': 3000},
        'distanceWalkingRunning': {'unit': 'km', 'base_value': 6.0, 'variance': 2.0},
        'heartRate': {'unit': 'bpm', 'base_value': 70, 'variance': 15},
        'activeEnergyBurned': {'unit': 'kcal', 'base_value': 400, 'variance': 150},
        'basalEnergyBurned': {'unit': 'kcal', 'base_value': 1500, 'variance': 100},
        'flightsClimbed': {'unit': 'count', 'base_value': 5, 'variance': 3},
    }
    
    base_date = datetime.now() - timedelta(days=days)
    files_created = 0
    
    for day_offset in range(days):
        current_date = base_date + timedelta(days=day_offset)
        dt_str = current_date.strftime('%Y-%m-%d')
        
        # Generate data points for this day
        rows = []
        
        for data_type, config in data_types.items():
            # Generate multiple samples per day (simulating hourly data)
            samples_per_day = random.randint(8, 24)
            
            for sample in range(samples_per_day):
                # Add some variance to make it realistic
                value = max(0, config['base_value'] + random.gauss(0, config['variance']))
                
                # Create timestamp for this sample
                hour = sample % 24
                sample_time = current_date.replace(hour=hour, minute=random.randint(0, 59))
                timestamp_str = sample_time.isoformat()
                timestamp_unix = int(sample_time.timestamp())
                
                rows.append({
                    'data_type': data_type,
                    'value': round(value, 2),
                    'timestamp': timestamp_str,
                    'timestamp_unix': timestamp_unix,
                    'unit': config['unit'],
                    'source_name': 'Apple Watch',
                    'source_version': '10.0',
                    'device': 'Apple Watch Series 9',
                    'metadata': '{}'
                })
        
        if rows:
            # Create Parquet file in memory
            table = pa.Table.from_pylist(rows)
            buffer = BytesIO()
            pq.write_table(table, buffer, compression='snappy')
            buffer.seek(0)
            
            # Upload to S3 with proper partitioning
            s3_key = f"health-data/raw/tenant_id={tenant_id}/dt={dt_str}/data.parquet"
            
            try:
                s3.put_object(
                    Bucket=settings.s3_bucket,
                    Key=s3_key,
                    Body=buffer.getvalue(),
                    ContentType='application/octet-stream'
                )
                files_created += 1
                if files_created % 5 == 0:
                    print(f"  Created {files_created} files...")
            except Exception as e:
                print(f"  ❌ Error uploading {s3_key}: {e}")
                return False
    
    print()
    print(f"✅ Created {files_created} Parquet files in S3")
    print()
    print("Next steps:")
    print("1. Wait 1-2 minutes for S3/Athena to recognize new partitions")
    print("2. Run: ALTER TABLE health_data_lake.health_data_raw ADD PARTITION (tenant_id='{}', dt='YYYY-MM-DD')".format(tenant_id))
    print("   OR use MSCK REPAIR TABLE (if supported)")
    print("3. Refresh gold tables using: ./create_gold_tables_for_tenant.sh")
    print()
    print("Or query directly - Athena should auto-discover partitions if using partition projection")
    
    return True

if __name__ == '__main__':
    import sys
    
    tenant_id = sys.argv[1] if len(sys.argv) > 1 else 'rajasaikatukuri'
    days = int(sys.argv[2]) if len(sys.argv) > 2 else 30
    
    print("=" * 60)
    print("Sample Health Data Generator")
    print("=" * 60)
    print()
    print(f"Tenant ID: {tenant_id}")
    print(f"Days: {days}")
    print(f"S3 Bucket: {settings.s3_bucket}")
    print(f"Region: {settings.aws_region}")
    print()
    
    confirm = input("This will create sample data in S3. Continue? (yes/no): ")
    if confirm.lower() != 'yes':
        print("Cancelled.")
        sys.exit(0)
    
    print()
    success = generate_sample_data(tenant_id, days)
    
    if success:
        print("✅ Sample data generation complete!")
        print()
        print("Now you can:")
        print("1. Query the data in Athena")
        print("2. Refresh gold tables")
        print("3. Test the chat interface")
    else:
        print("❌ Sample data generation failed")
        sys.exit(1)



