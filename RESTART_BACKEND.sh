#!/bin/bash
# Restart backend server

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "🔄 Restarting Backend Server"
echo "=========================================="
echo ""

# Step 1: Stop existing backend
echo "Step 1: Stopping existing backend..."
./STOP_ALL.sh 2>/dev/null || true

# Kill any processes on port 8000
PORT_8000=$(lsof -ti:8000 2>/dev/null || echo "")
if [ -n "$PORT_8000" ]; then
    echo "   Killing processes on port 8000: $PORT_8000"
    kill $PORT_8000 2>/dev/null || true
    sleep 2
fi

# Step 2: Start backend
echo ""
echo "Step 2: Starting backend..."
cd backend

# Activate venv
if [ ! -d "venv" ]; then
    echo "   Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

# Install dependencies if needed
echo "   Checking dependencies..."
pip install -q -r requirements.txt 2>/dev/null || true

# Create .env if missing
if [ ! -f ".env" ]; then
    echo "   Creating .env file..."
    cat > .env <<EOF
# AWS Configuration
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
fi

echo ""
echo "=========================================="
echo "🌟 Starting Backend Server"
echo "=========================================="
echo ""
echo "📍 Backend URL: http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs"
echo "❤️  Health Check: http://localhost:8000/health"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start server
python3 main.py

