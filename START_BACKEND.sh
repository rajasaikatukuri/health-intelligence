#!/bin/bash
# Complete Backend Activation Script
# Run this after restarting your laptop

set -e

cd "$(dirname "$0")/backend"

echo "=========================================="
echo "🚀 Health Intelligence Platform - Backend"
echo "=========================================="
echo ""

# Step 1: Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Step 1: Creating Python virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Step 2: Activate venv
echo ""
echo "🔌 Step 2: Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo "   Python: $(which python3)"
echo "   Python version: $(python3 --version)"

# Step 3: Install/upgrade dependencies
echo ""
echo "📥 Step 3: Installing dependencies..."
pip install --upgrade pip -q
pip install -q -r requirements.txt
echo "✅ Dependencies installed"

# Step 4: Create .env if missing
if [ ! -f ".env" ]; then
    echo ""
    echo "⚙️  Step 4: Creating .env configuration file..."
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
    echo "✅ .env file created"
else
    echo ""
    echo "✅ .env file already exists"
    # Ensure AWS_REGION is correct
    if grep -q "AWS_REGION=" .env; then
        sed -i.bak 's/^AWS_REGION=.*/AWS_REGION=us-east-2/' .env 2>/dev/null || \
        sed -i '' 's/^AWS_REGION=.*/AWS_REGION=us-east-2/' .env
    fi
fi

# Step 5: Verify Ollama is running (optional check)
echo ""
echo "🔍 Step 5: Checking Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama is running"
else
    echo "⚠️  Ollama is not running. Start it with: ollama serve"
    echo "   Or install with: brew install ollama"
fi

# Step 6: Start the server
echo ""
echo "=========================================="
echo "🌟 Starting Backend Server"
echo "=========================================="
echo ""
echo "📍 Backend URL: http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs"
echo "❤️  Health Check: http://localhost:8000/health"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python3 main.py




