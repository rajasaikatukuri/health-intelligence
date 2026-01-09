#!/bin/bash
# Check and fix AWS region configuration

cd "$(dirname "$0")"

echo "Checking AWS region configuration..."
echo ""

# Check if .env exists
if [ -f ".env" ]; then
    echo "Current .env file:"
    grep -E "AWS_REGION|aws_region" .env || echo "  (no AWS_REGION found)"
    echo ""
    
    # Update to us-east-2
    if grep -q "AWS_REGION=" .env; then
        sed -i.bak 's/^AWS_REGION=.*/AWS_REGION=us-east-2/' .env
        echo "✅ Updated AWS_REGION to us-east-2 in .env"
    else
        echo "AWS_REGION=us-east-2" >> .env
        echo "✅ Added AWS_REGION=us-east-2 to .env"
    fi
else
    echo "Creating .env file with AWS_REGION=us-east-2..."
    cat > .env <<EOF
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
    echo "✅ Created .env file"
fi

echo ""
echo "Current .env AWS_REGION:"
grep "AWS_REGION" .env

echo ""
echo "To apply changes, restart the backend server."





