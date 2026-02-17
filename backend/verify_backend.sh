#!/bin/bash
# Verify which backend is running and help start the correct one

echo "=========================================="
echo "Backend Verification"
echo "=========================================="
echo ""

# Check what's on port 8000
echo "1. Checking what's running on port 8000..."
curl -s http://localhost:8000/health 2>/dev/null && echo "" || echo "  Nothing responding on port 8000"
echo ""

# Check if health-intelligence backend is running
echo "2. Expected health-intelligence backend response:"
echo '   {"status": "healthy", "aws_region": "us-east-2", "athena_database": "health_data_lake"}'
echo ""

# Check if there's a process on port 8000
echo "3. Processes using port 8000:"
lsof -i :8000 2>/dev/null || echo "  (No process found or lsof not available)"
echo ""

echo "=========================================="
echo "To Start Health Intelligence Backend:"
echo "=========================================="
echo ""
echo "cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend"
echo "./start.sh"
echo ""
echo "Then verify:"
echo "curl http://localhost:8000/health"
echo ""






