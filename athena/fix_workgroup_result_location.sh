#!/bin/bash
# Fix workgroup result location to match your bucket

set -e

REGION="us-east-2"
WORKGROUP="health-data-tenant-queries"
CORRECT_BUCKET="health-data-lake-640768199126-us-east-2"
CURRENT_BUCKET="health-data-lake-248894199474-us-east-2"

echo "=========================================="
echo "Fixing Workgroup Result Location"
echo "=========================================="
echo ""
echo "Current result location: s3://$CURRENT_BUCKET/athena-results/"
echo "Should be: s3://$CORRECT_BUCKET/athena-results/"
echo ""
echo "Note: This requires updating the workgroup configuration."
echo "You can do this via AWS Console:"
echo ""
echo "1. Go to: AWS Console → Athena → Workgroups"
echo "2. Click on: $WORKGROUP"
echo "3. Click 'Edit'"
echo "4. Under 'Query result location':"
echo "   Change to: s3://$CORRECT_BUCKET/athena-results/"
echo "5. Save changes"
echo ""
echo "Or use AWS CLI (if you have permissions):"
echo ""
echo "  aws athena update-work-group \\"
echo "    --work-group $WORKGROUP \\"
echo "    --region $REGION \\"
echo "    --configuration-updates \\"
echo "      ResultConfiguration={OutputLocation=s3://$CORRECT_BUCKET/athena-results/}"
echo ""
echo "Important: The result location bucket also needs:"
echo "  - S3 write permissions (to save query results)"
echo "  - Same permissions as the data bucket"
echo ""



