# Quick Fix Summary

## The Problem

Your IAM user (`rajasaik-cli`) doesn't have S3 read permissions, and Athena is using your user credentials (no execution role set).

## The Fix (Choose One)

### Option 1: Add S3 Permissions to Your User (Recommended)

**Via AWS Console:**
1. Go to: **AWS Console → IAM → Users → rajasaik-cli**
2. Click **"Add permissions"** → **"Attach policies directly"**
3. Search for: **`AmazonS3ReadOnlyAccess`**
4. Check the box and click **"Add permissions"**

**Via AWS CLI:**
```bash
aws iam attach-user-policy \
  --user-name rajasaik-cli \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### Option 2: Create Execution Role for Workgroup

1. Create a new IAM role for Athena
2. Attach S3 read permissions to that role
3. Update workgroup to use that execution role

## After Fixing Permissions

1. **Wait 1-2 minutes** for IAM changes to propagate
2. **Test S3 access:**
   ```bash
   aws s3 ls s3://health-data-lake-640768199126-us-east-2/health-data/raw/tenant_id=rajasaikatukuri/
   ```
3. **Test Athena query:**
   ```bash
   cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
   ./fix_and_refresh_all.sh
   ```
4. **If successful, refresh gold tables:**
   ```bash
   ./create_gold_tables_for_tenant.sh rajasaikatukuri
   ```

## Additional Issue: Result Location

Your workgroup result location is in a different bucket:
- Current: `s3://health-data-lake-248894199474-us-east-2/athena-results/`
- Should be: `s3://health-data-lake-640768199126-us-east-2/athena-results/`

**Fix this too:**
1. Go to: **AWS Console → Athena → Workgroups → health-data-tenant-queries**
2. Click **"Edit"**
3. Change **"Query result location"** to: `s3://health-data-lake-640768199126-us-east-2/athena-results/`
4. Save

## Quick Test

After adding permissions, test immediately:

```bash
# Test 1: Can you read S3?
aws s3 ls s3://health-data-lake-640768199126-us-east-2/health-data/raw/tenant_id=rajasaikatukuri/

# Test 2: Try Athena query
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
./try_without_execution_role.sh
```

If both work, you're good to go! 🎉


