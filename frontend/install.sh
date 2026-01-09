#!/bin/bash
# Install frontend dependencies with proper versions

set -e

cd "$(dirname "$0")"

echo "📦 Installing frontend dependencies..."
echo ""

# Clean up
echo "Cleaning up old installations..."
rm -rf node_modules package-lock.json

# Install with updated package.json
echo "Installing dependencies..."
npm install

echo ""
echo "✅ Dependencies installed!"
echo ""
echo "Start the frontend:"
echo "  npm run dev"





