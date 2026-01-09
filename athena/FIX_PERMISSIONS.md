# Fixing Athena S3 Permissions

## Problem
Athena is getting `PERMISSION_DENIED (403)` when trying to read from S3. This is an IAM permissions issue.

## Quick Fix

### Option 1: Check Workgroup Service Role

1. Go to AWS Console → Athena → Workgroups
2. Select workgroup: `health-data-tenant-queries`
3. Check the "Service role" or "IAM role" attached
4. That role needs S3 permissions

### Option 2: Add S3 Permissions to Athena Service Role

The Athena service role needs these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::health-data-lake-640768199126-us-east-2",
                "arn:aws:s3:::health-data-lake-640768199126-us-east-2/*"
            ]
        }
    ]
}
```

### Option 3: Update Bucket Policy

Add this to your S3 bucket policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAthenaAccess",
            "Effect": "Allow",
            "Principal": {
                "Service": "athena.amazonaws.com"
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::health-data-lake-640768199126-us-east-2",
                "arn:aws:s3:::health-data-lake-640768199126-us-east-2/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "640768199126"
                }
            }
        }
    ]
}
```

### Option 4: Use AWS CLI to Check/Fix

```bash
# Find the Athena workgroup service role
aws athena get-work-group \
    --work-group health-data-tenant-queries \
    --region us-east-2 \
    --query 'WorkGroup.Configuration.ResultConfiguration.EncryptionConfiguration' \
    --output text

# Or check workgroup settings
aws athena get-work-group \
    --work-group health-data-tenant-queries \
    --region us-east-2
```

## Quick Test: Use Gold Tables Directly

Since you already have gold tables, let's check if they work:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
chmod +x check_gold_tables.sh
./check_gold_tables.sh
```

If gold tables have data and are accessible, the chat interface should work! The chat queries gold tables, not raw tables.

## Alternative: Use Your AWS Account Admin

If you have admin access:
1. Go to IAM → Roles
2. Find the Athena service role (usually named like `AmazonAthena-*` or attached to the workgroup)
3. Attach the `AmazonS3ReadOnlyAccess` policy (or create custom policy above)

## After Fixing Permissions

Once permissions are fixed:
1. Test raw table access
2. Refresh gold tables if needed
3. Try chat interface queries


