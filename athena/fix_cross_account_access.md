# Fix Cross-Account Access Issue

## The Problem

Your AWS credentials are for account: **248894199474**
But your S3 bucket is in account: **640768199126**

This is a **cross-account access** issue. Even with full S3 permissions, you can't access buckets in a different account unless:
1. The bucket policy allows your account/user
2. You assume a role in the target account
3. You use credentials from the target account

## Solutions

### Option 1: Use Credentials from Account 640768199126 (Easiest)

If you have access to account `640768199126`, switch to those credentials:

```bash
# Configure AWS CLI with credentials from account 640768199126
aws configure --profile health-data
# Enter credentials for account 640768199126

# Then use that profile
export AWS_PROFILE=health-data
```

### Option 2: Add Bucket Policy (If You Control Both Accounts)

Add a bucket policy to `health-data-lake-640768199126-us-east-2` that allows your user from account `248894199474`:

1. Go to: **S3 Console → health-data-lake-640768199126-us-east-2 → Permissions → Bucket policy**
2. Add this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCrossAccountAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::248894199474:user/rajasaik-cli"
            },
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

### Option 3: Assume Role (If You Have Permission)

If you have permission to assume a role in account `640768199126`:

```bash
# Assume role in target account
aws sts assume-role \
  --role-arn arn:aws:iam::640768199126:role/AthenaAccessRole \
  --role-session-name athena-session \
  --profile health-data
```

Then use those temporary credentials.

## Quick Check: Which Account Has Your Data?

Run this to see which account you can actually access:

```bash
# List buckets you can access
aws s3 ls

# Check if bucket exists in your account
aws s3 ls s3://health-data-lake-248894199474-us-east-2/ 2>&1
```

## Recommended Next Steps

1. **Verify which account has your data:**
   - Check if you have credentials for account `640768199126`
   - Or check if the bucket exists in account `248894199474` with a different name

2. **If data is in 640768199126:**
   - Switch to credentials from that account
   - Or set up cross-account access (bucket policy or assume role)

3. **If data is actually in 248894199474:**
   - Update all scripts to use the correct bucket name
   - The bucket might be: `health-data-lake-248894199474-us-east-2`

