#!/bin/bash
# Stop both backend and frontend servers

cd "$(dirname "$0")"

echo "=========================================="
echo "🛑 Stopping Health Intelligence Platform"
echo "=========================================="
echo ""

# Try to read PIDs from file
if [ -f ".server_pids" ]; then
    PIDS=$(cat .server_pids)
    echo "Found saved PIDs: $PIDS"
    kill $PIDS 2>/dev/null && echo "✅ Stopped servers" || echo "⚠️  Servers may have already stopped"
    rm -f .server_pids
fi

# Kill by process name
echo ""
echo "Checking for running processes..."

# Backend (Python)
BACKEND_PIDS=$(ps aux | grep "[p]ython3.*main.py" | awk '{print $2}' || echo "")
if [ -n "$BACKEND_PIDS" ]; then
    echo "Stopping backend processes: $BACKEND_PIDS"
    kill $BACKEND_PIDS 2>/dev/null && echo "✅ Backend stopped" || echo "⚠️  Backend already stopped"
else
    echo "✅ No backend processes found"
fi

# Frontend (Next.js)
FRONTEND_PIDS=$(ps aux | grep "[n]ext-server" | awk '{print $2}' || echo "")
if [ -z "$FRONTEND_PIDS" ]; then
    FRONTEND_PIDS=$(ps aux | grep "[n]ode.*next" | awk '{print $2}' || echo "")
fi

if [ -n "$FRONTEND_PIDS" ]; then
    echo "Stopping frontend processes: $FRONTEND_PIDS"
    kill $FRONTEND_PIDS 2>/dev/null && echo "✅ Frontend stopped" || echo "⚠️  Frontend already stopped"
else
    echo "✅ No frontend processes found"
fi

# Kill by port
echo ""
echo "Checking ports 8000 and 3000..."

PORT_8000=$(lsof -ti:8000 2>/dev/null || echo "")
if [ -n "$PORT_8000" ]; then
    echo "Killing process on port 8000: $PORT_8000"
    kill $PORT_8000 2>/dev/null && echo "✅ Port 8000 freed" || echo "⚠️  Could not free port 8000"
fi

PORT_3000=$(lsof -ti:3000 2>/dev/null || echo "")
if [ -n "$PORT_3000" ]; then
    echo "Killing process on port 3000: $PORT_3000"
    kill $PORT_3000 2>/dev/null && echo "✅ Port 3000 freed" || echo "⚠️  Could not free port 3000"
fi

echo ""
echo "✅ All servers stopped!"
echo ""

