#!/bin/bash
# Quick start script - stops existing servers and starts fresh

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "🚀 Quick Start - Health Intelligence Platform"
echo "=========================================="
echo ""

# Stop any existing servers
echo "🛑 Stopping any existing servers..."
./STOP_ALL.sh 2>/dev/null || true
sleep 2

# Make scripts executable
chmod +x START_ALL.sh STOP_ALL.sh 2>/dev/null || true

# Start both servers (option 1 - same terminal)
echo ""
echo "🚀 Starting both servers..."
echo ""

# Auto-select option 1 (same terminal)
echo "1" | ./START_ALL.sh

