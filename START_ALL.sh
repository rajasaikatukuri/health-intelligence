#!/bin/bash
# Start both backend and frontend together
# Options: same terminal (with logs) or separate terminals

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "🚀 Health Intelligence Platform"
echo "=========================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
else
    IS_MACOS=false
fi

# Make scripts executable
chmod +x START_BACKEND.sh START_FRONTEND.sh 2>/dev/null || true

# Ask user preference
echo "How would you like to run the servers?"
echo ""
echo "1. Same terminal (logs shown together) - Recommended"
echo "2. Separate terminal windows (macOS only)"
echo "3. Background with log files"
echo ""
read -p "Choose option (1-3) [default: 1]: " choice
choice=${choice:-1}

case $choice in
    1)
        echo ""
        echo "Starting both servers in same terminal..."
        echo "Press Ctrl+C to stop both"
        echo ""
        
        # Function to cleanup on exit
        cleanup() {
            echo ""
            echo "Stopping servers..."
            kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
            exit
        }
        trap cleanup INT TERM
        
        # Store root directory
        ROOT_DIR="$(pwd)"
        
        # Start backend in background
        echo "📡 Starting Backend..."
        cd backend
        if [ ! -d "venv" ]; then
            python3 -m venv venv
        fi
        source venv/bin/activate
        
        # Create .env if missing
        if [ ! -f ".env" ]; then
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
        
        # Create log file first in root directory
        touch "$ROOT_DIR/backend.log"
        python3 main.py >> "$ROOT_DIR/backend.log" 2>&1 &
        BACKEND_PID=$!
        echo "✅ Backend started (PID: $BACKEND_PID)"
        echo "   Logs: tail -f $ROOT_DIR/backend.log"
        
        # Wait for backend to be ready
        echo "   Waiting for backend to start..."
        for i in {1..30}; do
            if curl -s http://localhost:8000/health > /dev/null 2>&1; then
                echo "✅ Backend is ready!"
                break
            fi
            sleep 1
        done
        
        # Start frontend in background
        cd "$ROOT_DIR/frontend"
        echo ""
        echo "🎨 Starting Frontend..."
        if [ ! -d "node_modules" ]; then
            echo "   Installing dependencies (this may take a minute)..."
            npm install --legacy-peer-deps > /dev/null 2>&1
        fi
        
        # Create log file first in root directory
        touch "$ROOT_DIR/frontend.log"
        npm run dev >> "$ROOT_DIR/frontend.log" 2>&1 &
        FRONTEND_PID=$!
        echo "✅ Frontend started (PID: $FRONTEND_PID)"
        echo "   Logs: tail -f $ROOT_DIR/frontend.log"
        
        echo ""
        echo "=========================================="
        echo "✅ Both servers are running!"
        echo "=========================================="
        echo ""
        echo "📍 Backend:  http://localhost:8000"
        echo "📍 Frontend: http://localhost:3000"
        echo "📚 API Docs: http://localhost:8000/docs"
        echo ""
        echo "📋 View logs:"
        echo "   tail -f backend.log    # Backend"
        echo "   tail -f frontend.log   # Frontend"
        echo ""
        echo "🛑 To stop: Press Ctrl+C"
        echo ""
        echo "⏳ Opening browser in 5 seconds..."
        sleep 5
        
        # Open browser
        if command -v open > /dev/null; then
            open http://localhost:3000
        elif command -v xdg-open > /dev/null; then
            xdg-open http://localhost:3000
        fi
        
        # Show logs
        echo ""
        echo "=========================================="
        echo "📋 Live Logs (Ctrl+C to stop)"
        echo "=========================================="
        echo ""
        
        # Wait a moment for logs to be created
        sleep 3
        
        # Go back to root directory for log files
        cd "$ROOT_DIR"
        
        # Check if log files exist
        if [ -f "backend.log" ] && [ -f "frontend.log" ]; then
            # Use multitail if available, otherwise show combined logs
            if command -v multitail > /dev/null; then
                multitail -s 2 backend.log frontend.log
            else
                echo "📡 Backend logs (last 10 lines):"
                echo "----------------------------------------"
                tail -n 10 backend.log 2>/dev/null || echo "No backend logs yet"
                echo ""
                echo "🎨 Following frontend logs (Ctrl+C to stop):"
                echo "----------------------------------------"
                tail -f frontend.log
            fi
        else
            echo "⚠️  Log files not found yet. They will be created as servers run."
            echo ""
            echo "To view logs manually:"
            echo "   tail -f $ROOT_DIR/backend.log"
            echo "   tail -f $ROOT_DIR/frontend.log"
            echo ""
            echo "Or check server status:"
            echo "   curl http://localhost:8000/health"
            echo "   curl http://localhost:3000"
            echo ""
            echo "Press Ctrl+C to stop servers"
            # Keep script running
            wait
        fi
        ;;
        
    2)
        if [ "$IS_MACOS" = false ]; then
            echo "❌ Separate terminals only work on macOS"
            echo "   Falling back to option 1..."
            sleep 2
            # Recursively call with option 1
            echo "1" | bash "$0"
            exit
        fi
        
        echo ""
        echo "Opening separate terminal windows..."
        
        # Get absolute paths
        BACKEND_SCRIPT="$(pwd)/START_BACKEND.sh"
        FRONTEND_SCRIPT="$(pwd)/START_FRONTEND.sh"
        
        # Open backend in new terminal
        echo "📡 Opening Backend terminal..."
        osascript -e "tell application \"Terminal\" to do script \"cd '$(pwd)' && ./START_BACKEND.sh\""
        
        # Wait a bit
        sleep 3
        
        # Open frontend in new terminal
        echo "🎨 Opening Frontend terminal..."
        osascript -e "tell application \"Terminal\" to do script \"cd '$(pwd)' && ./START_FRONTEND.sh\""
        
        echo ""
        echo "✅ Both servers starting in separate terminals"
        echo ""
        echo "📍 Backend: http://localhost:8000"
        echo "📍 Frontend: http://localhost:3000"
        echo ""
        echo "Wait ~30 seconds, then open: http://localhost:3000"
        ;;
        
    3)
        echo ""
        echo "Starting both servers in background..."
        
        # Start backend
        cd backend
        if [ ! -d "venv" ]; then
            python3 -m venv venv
        fi
        source venv/bin/activate
        
        if [ ! -f ".env" ]; then
            cat > .env <<EOF
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
LLM_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
        fi
        
        python3 main.py > ../backend.log 2>&1 &
        BACKEND_PID=$!
        echo "✅ Backend started (PID: $BACKEND_PID)"
        
        sleep 5
        
        # Start frontend
        cd ../frontend
        if [ ! -d "node_modules" ]; then
            echo "Installing frontend dependencies..."
            npm install --legacy-peer-deps > /dev/null 2>&1
        fi
        
        npm run dev > ../frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo "✅ Frontend started (PID: $FRONTEND_PID)"
        
        echo ""
        echo "=========================================="
        echo "✅ Both servers are running in background!"
        echo "=========================================="
        echo ""
        echo "📍 Backend:  http://localhost:8000"
        echo "📍 Frontend: http://localhost:3000"
        echo ""
        echo "📋 View logs:"
        echo "   tail -f backend.log"
        echo "   tail -f frontend.log"
        echo ""
        echo "🛑 To stop:"
        echo "   kill $BACKEND_PID $FRONTEND_PID"
        echo ""
        echo "💾 PIDs saved to: .server_pids"
        echo "$BACKEND_PID $FRONTEND_PID" > .server_pids
        ;;
        
    *)
        echo "Invalid option. Using option 1..."
        sleep 1
        echo "1" | bash "$0"
        exit
        ;;
esac

