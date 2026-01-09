#!/bin/bash
# Fix Python dependencies

set -e

cd "$(dirname "$0")"

echo "🔧 Fixing Python dependencies..."
echo ""

# Remove old venv if exists
if [ -d "venv" ]; then
    echo "Removing old virtual environment..."
    rm -rf venv
fi

# Create new venv
echo "Creating new virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Uninstall conflicting jose package if exists
echo "Removing conflicting packages..."
pip uninstall -y jose 2>/dev/null || true

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

echo ""
echo "✅ Dependencies installed successfully!"
echo ""
echo "Now start the backend:"
echo "  source venv/bin/activate"
echo "  python3 main.py"
echo ""
echo "Or use:"
echo "  ./start.sh"





