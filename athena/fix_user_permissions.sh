#!/bin/bash
# Instructions to fix IAM user permissions

set -e

BUCKET="health-data-lake-640768199126-us-east-2"
USER_NAME="rajasaik-cli"

echo "=========================================="
echo "Fix IAM User Permissions"
echo "=========================================="
echo ""
echo "Your IAM user: $USER_NAME"
echo "Cannot read S3 bucket: $BUCKET"
echo ""
echo "You need to add S3 permissions to your IAM user."
echo ""
echo "Option 1: Via AWS Console (Easiest)"
echo "-----------------------------------"
echo "1. Go to: AWS Console → IAM → Users → $USER_NAME"
echo "2. Click 'Add permissions' → 'Attach policies directly'"
echo "3. Search for and attach: AmazonS3ReadOnlyAccess"
echo "4. Click 'Add permissions'"
echo ""
echo "Option 2: Via AWS CLI"
echo "---------------------"
echo "Run this command:"
echo ""
echo "  aws iam attach-user-policy \\"
echo "    --user-name $USER_NAME \\"
echo "    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
echo ""
echo "Option 3: Custom Policy (More Restrictive)"
echo "-------------------------------------------"
echo "Create a custom policy with this JSON:"
echo ""
cat <<EOF
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
                "arn:aws:s3:::$BUCKET",
                "arn:aws:s3:::$BUCKET/*"
            ]
        }
    ]
}
EOF
echo ""
echo "Then attach it to your user."
echo ""
echo "After adding permissions:"
echo "1. Wait 1-2 minutes for propagation"
echo "2. Test with: aws s3 ls s3://$BUCKET/health-data/raw/"
echo "3. Then try Athena queries again"
echo ""



