#!/bin/bash
# Complete deployment script - cleans, commits, and prepares for GitHub

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "🚀 Preparing for GitHub Deployment"
echo "=========================================="
echo ""

# Step 1: Clean log files
echo "Step 1: Cleaning log files..."
rm -f *.log backend.log frontend.log 2>/dev/null || true
echo "✅ Log files cleaned"
echo ""

# Step 2: Remove Python cache
echo "Step 2: Cleaning Python cache..."
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
echo "✅ Python cache cleaned"
echo ""

# Step 3: Verify .gitignore exists
echo "Step 3: Checking .gitignore..."
if [ ! -f ".gitignore" ]; then
    echo "❌ .gitignore not found!"
    exit 1
fi
echo "✅ .gitignore found"
echo ""

# Step 4: Check git status
echo "Step 4: Checking git status..."
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
    echo "✅ Git initialized"
else
    echo "✅ Git repository already exists"
fi
echo ""

# Step 5: Check for secrets before adding
echo "Step 5: Checking for secrets in code..."
SECRETS_FOUND=false

if git ls-files | grep -q "\.env$"; then
    echo "⚠️  WARNING: .env files found in git!"
    echo "   Removing from git (keeping local files)..."
    git rm --cached backend/.env 2>/dev/null || true
    git rm --cached frontend/.env.local 2>/dev/null || true
    SECRETS_FOUND=true
fi

if grep -r "AKIA" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null | grep -v ".git" | grep -v "node_modules" | grep -v "venv"; then
    echo "⚠️  WARNING: Potential AWS keys found in code!"
    SECRETS_FOUND=true
fi

if grep -r "sk-proj-" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null | grep -v ".git" | grep -v "node_modules" | grep -v "venv"; then
    echo "⚠️  WARNING: Potential OpenAI keys found in code!"
    SECRETS_FOUND=true
fi

if [ "$SECRETS_FOUND" = false ]; then
    echo "✅ No secrets found in code"
fi
echo ""

# Step 6: Add files
echo "Step 6: Adding files to git..."
git add .
echo "✅ Files added"
echo ""

# Step 7: Show what will be committed
echo "Step 7: Files to be committed:"
git status --short | head -20
echo ""

# Step 8: Summary
echo "=========================================="
echo "✅ Preparation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Review what will be committed:"
echo "   git status"
echo ""
echo "2. Commit the changes:"
echo "   git commit -m 'Initial commit - Health Intelligence Platform ready for Render'"
echo ""
echo "3. Create GitHub repository at:"
echo "   https://github.com/new"
echo ""
echo "4. Add remote and push:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git"
echo "   git push -u origin main"
echo ""
echo "5. Deploy to Render:"
echo "   - Go to https://dashboard.render.com"
echo "   - Click 'New +' → 'Blueprint'"
echo "   - Connect GitHub repository"
echo "   - Click 'Apply'"
echo ""
echo "For detailed instructions, see:"
echo "   - GITHUB_SETUP.md"
echo "   - DEPLOY_TO_RENDER.md"
echo "   - QUICK_DEPLOY_STEPS.md"
echo ""

