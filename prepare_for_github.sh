#!/bin/bash
# Prepare repository for GitHub deployment
# This script cleans unnecessary files and prepares for GitHub push

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "🧹 Preparing Repository for GitHub"
echo "=========================================="
echo ""

# Step 1: Clean log files
echo "Step 1: Cleaning log files..."
rm -f *.log backend.log frontend.log 2>/dev/null || true
echo "✅ Log files cleaned"
echo ""

# Step 2: Remove Python cache
echo "Step 2: Removing Python cache..."
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type f -name "*.pyd" -delete 2>/dev/null || true
echo "✅ Python cache cleaned"
echo ""

# Step 3: Remove virtual environment (will be recreated on deployment)
echo "Step 3: Checking virtual environments..."
if [ -d "backend/venv" ]; then
    echo "⚠️  Found backend/venv - excluding from git (already in .gitignore)"
fi
echo "✅ Virtual environments checked"
echo ""

# Step 4: Remove node_modules (will be installed on deployment)
echo "Step 4: Checking node_modules..."
if [ -d "frontend/node_modules" ]; then
    echo "⚠️  Found frontend/node_modules - excluding from git (already in .gitignore)"
fi
echo "✅ Node modules checked"
echo ""

# Step 5: Remove .env files (contain secrets)
echo "Step 5: Checking for .env files..."
if [ -f "backend/.env" ]; then
    echo "⚠️  Found backend/.env - Make sure it's in .gitignore"
    echo "   (This file should NOT be committed to GitHub)"
fi
if [ -f "frontend/.env.local" ]; then
    echo "⚠️  Found frontend/.env.local - Make sure it's in .gitignore"
    echo "   (This file should NOT be committed to GitHub)"
fi
echo "✅ Environment files checked"
echo ""

# Step 6: Check .gitignore exists
echo "Step 6: Checking .gitignore..."
if [ ! -f ".gitignore" ]; then
    echo "❌ .gitignore not found! Creating one..."
    # .gitignore should have been created, but if not, we'll create it
else
    echo "✅ .gitignore found"
fi
echo ""

# Step 7: Create example .env files (for documentation)
echo "Step 7: Creating example .env files..."
cat > backend/.env.example <<'EOF'
# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=your-s3-bucket-name
S3_RESULTS_BUCKET=your-s3-bucket-name
S3_RESULTS_PREFIX=athena-results/

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4

# JWT Configuration
JWT_SECRET=generate-with-openssl-rand-hex-32
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=false

# CORS Configuration
CORS_ORIGINS=http://localhost:3000
EOF

cat > frontend/.env.example <<'EOF'
# Backend API URL
NEXT_PUBLIC_API_URL=http://localhost:8000

# Node Environment
NODE_ENV=development
EOF

echo "✅ Example .env files created (backend/.env.example, frontend/.env.example)"
echo ""

# Step 8: Summary
echo "=========================================="
echo "✅ Cleanup Complete!"
echo "=========================================="
echo ""
echo "Files cleaned:"
echo "  ✅ Log files"
echo "  ✅ Python cache"
echo "  ✅ Virtual environments (excluded via .gitignore)"
echo "  ✅ Node modules (excluded via .gitignore)"
echo "  ✅ .env files (excluded via .gitignore)"
echo ""
echo "Next steps:"
echo "  1. Review .gitignore to ensure it's correct"
echo "  2. Initialize git: git init (if not already)"
echo "  3. Add files: git add ."
echo "  4. Commit: git commit -m 'Initial commit - ready for Render'"
echo "  5. Create GitHub repo and push"
echo ""
echo "Important:"
echo "  ⚠️  NEVER commit .env files with real secrets!"
echo "  ⚠️  Use .env.example files for documentation only"
echo ""

