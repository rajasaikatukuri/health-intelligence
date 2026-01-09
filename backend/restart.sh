#!/bin/bash
# Stop and restart the backend server

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "🛑 Stopping Backend Server"
echo "=========================================="
echo ""

# Find and kill process on port 8000
PID=$(lsof -ti :8000 2>/dev/null || echo "")

if [ -n "$PID" ]; then
    echo "Found process $PID on port 8000, stopping it..."
    kill -9 $PID 2>/dev/null || echo "  (Process already stopped)"
    sleep 2
    echo "✅ Backend stopped"
else
    echo "✅ No process found on port 8000"
fi

echo ""
echo "=========================================="
echo "🚀 Starting Backend Server"
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

# Check for .env file
if [ ! -f ".env" ]; then
    echo "⚠️  No .env file found. Creating default .env file..."
    cat > .env <<EOF
# AWS Configuration
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2

# LLM Configuration
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
    echo "✅ Created .env file with defaults"
    echo ""
fi

echo "Starting server..."
echo "Backend will be available at: http://localhost:8000"
echo "API docs at: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop"
echo ""

python3 main.py




