#!/bin/bash
# Start both backend and frontend in background
# Use this if ACTIVATE_ALL.sh doesn't work

cd "$(dirname "$0")"

echo "=========================================="
echo "🚀 Starting Health Intelligence Platform"
echo "=========================================="
echo ""

# Make scripts executable
chmod +x START_BACKEND.sh START_FRONTEND.sh

# Start backend in background
echo "📡 Starting Backend..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -q -r requirements.txt 2>/dev/null || true

# Create .env if missing
if [ ! -f ".env" ]; then
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
fi

# Start backend in background
python3 main.py > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "✅ Backend started (PID: $BACKEND_PID)"
echo "   Logs: tail -f backend.log"

# Wait a bit for backend to start
sleep 5

# Start frontend
cd ../frontend
echo ""
echo "🎨 Starting Frontend..."
if [ ! -d "node_modules" ]; then
    echo "   Installing dependencies (this may take a minute)..."
    npm install --legacy-peer-deps > /dev/null 2>&1
fi

# Start frontend in background
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
echo "✅ Frontend started (PID: $FRONTEND_PID)"
echo "   Logs: tail -f frontend.log"

echo ""
echo "=========================================="
echo "✅ Both servers are starting!"
echo "=========================================="
echo ""
echo "📍 Backend:  http://localhost:8000"
echo "📍 Frontend: http://localhost:3000"
echo ""
echo "📋 To view logs:"
echo "   tail -f backend.log    # Backend logs"
echo "   tail -f frontend.log    # Frontend logs"
echo ""
echo "🛑 To stop both servers:"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo ""
echo "⏳ Wait ~30 seconds, then open: http://localhost:3000"
echo ""

# Wait for user interrupt
trap "echo ''; echo 'Stopping servers...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

# Keep script running
wait




