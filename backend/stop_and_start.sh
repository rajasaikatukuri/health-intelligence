#!/bin/bash
# Stop any process on port 8000 and start the health-intelligence backend

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "Stopping any process on port 8000"
echo "=========================================="

# Find and kill process on port 8000
PID=$(lsof -ti :8000 2>/dev/null || echo "")

if [ -n "$PID" ]; then
    echo "Found process $PID on port 8000, stopping it..."
    kill -9 $PID 2>/dev/null || echo "  (Process already stopped)"
    sleep 1
    echo "✓ Port 8000 is now free"
else
    echo "✓ Port 8000 is already free"
fi

echo ""
echo "=========================================="
echo "Starting Health Intelligence Backend"
echo "=========================================="
echo ""

# Check if venv exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    echo "Installing dependencies..."
    pip install -q -r requirements.txt
else
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Ensure .env exists with correct region
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
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
    echo "✓ Created .env file"
else
    # Update AWS_REGION if it exists
    if grep -q "AWS_REGION=" .env; then
        sed -i.bak 's/^AWS_REGION=.*/AWS_REGION=us-east-2/' .env
        echo "✓ Updated AWS_REGION to us-east-2 in .env"
    else
        echo "AWS_REGION=us-east-2" >> .env
        echo "✓ Added AWS_REGION=us-east-2 to .env"
    fi
fi

echo ""
echo "Starting server..."
echo "Backend will be available at: http://localhost:8000"
echo "API docs at: http://localhost:8000/docs"
echo ""
echo "Expected health response:"
echo '  {"status": "healthy", "aws_region": "us-east-2", "athena_database": "health_data_lake"}'
echo ""
echo "Press Ctrl+C to stop"
echo ""

python3 main.py






