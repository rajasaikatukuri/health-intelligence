#!/bin/bash
# Complete Frontend Activation Script
# Run this after restarting your laptop

set -e

cd "$(dirname "$0")/frontend"

echo "=========================================="
echo "🎨 Health Intelligence Platform - Frontend"
echo "=========================================="
echo ""

# Step 1: Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Step 1: Installing Node.js dependencies..."
    echo "   This may take a few minutes..."
    npm install --legacy-peer-deps
    echo "✅ Dependencies installed"
else
    echo "✅ node_modules already exists"
    echo ""
    echo "🔄 Checking for updates..."
    npm install --legacy-peer-deps
    echo "✅ Dependencies up to date"
fi

# Step 2: Verify backend is running
echo ""
echo "🔍 Step 2: Checking backend connection..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend is running at http://localhost:8000"
else
    echo "⚠️  Backend is not running!"
    echo "   Start it first with: cd ../backend && ./START_BACKEND.sh"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 3: Start Next.js dev server
echo ""
echo "=========================================="
echo "🌟 Starting Frontend Server"
echo "=========================================="
echo ""
echo "📍 Frontend URL: http://localhost:3000"
echo "🔗 Backend API: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm run dev




