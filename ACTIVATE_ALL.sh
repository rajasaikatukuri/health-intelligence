#!/bin/bash
# Master script to start both backend and frontend in separate terminals
# This opens two terminal windows (macOS)

cd "$(dirname "$0")"

echo "=========================================="
echo "🚀 Starting Health Intelligence Platform"
echo "=========================================="
echo ""

# Get absolute paths
BACKEND_SCRIPT="$(pwd)/START_BACKEND.sh"
FRONTEND_SCRIPT="$(pwd)/START_FRONTEND.sh"

# Make scripts executable
chmod +x "$BACKEND_SCRIPT" "$FRONTEND_SCRIPT"

# Open backend in new terminal
echo "📡 Opening Backend terminal..."
osascript -e "tell application \"Terminal\" to do script \"cd '$(pwd)' && ./START_BACKEND.sh\""

# Wait a bit for backend to start
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
echo "Wait ~30 seconds for both to start, then open:"
echo "   http://localhost:3000"
echo ""




