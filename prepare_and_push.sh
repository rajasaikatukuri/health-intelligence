#!/bin/bash
# Prepare repository and push to GitHub

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "📤 Preparing Repository for GitHub Push"
echo "=========================================="
echo ""

# Step 1: Clean up
echo "Step 1: Cleaning up..."
rm -f *.log backend.log frontend.log 2>/dev/null || true
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
echo "✅ Cleanup complete"
echo ""

# Step 2: Check for secrets
echo "Step 2: Checking for secrets..."
if [ -f "backend/.env" ]; then
    echo "⚠️  Found backend/.env - Make sure it's in .gitignore"
    if git check-ignore backend/.env > /dev/null; then
        echo "✅ backend/.env is in .gitignore"
    else
        echo "❌ ERROR: backend/.env is NOT in .gitignore!"
        echo "   Add it to .gitignore before pushing"
        exit 1
    fi
fi

if [ -f "frontend/.env.local" ]; then
    echo "⚠️  Found frontend/.env.local - Make sure it's in .gitignore"
    if git check-ignore frontend/.env.local > /dev/null; then
        echo "✅ frontend/.env.local is in .gitignore"
    else
        echo "❌ ERROR: frontend/.env.local is NOT in .gitignore!"
        echo "   Add it to .gitignore before pushing"
        exit 1
    fi
fi
echo "✅ No secrets will be committed"
echo ""

# Step 3: Add all files
echo "Step 3: Adding files to git..."
git add .
echo "✅ Files added"
echo ""

# Step 4: Show what will be committed
echo "Step 4: Files to be committed:"
git status --short | head -30
echo ""

# Step 5: Check if anything to commit
if git diff --cached --quiet; then
    echo "⚠️  No changes to commit (everything already committed)"
else
    echo "Step 5: Committing changes..."
    git commit -m "Update: Health Intelligence Platform ready for use

- Updated README with comprehensive setup guide
- Fixed Dockerfile for Render deployment
- Updated render.yaml for free tier
- Added deployment documentation
- Production-ready configuration"
    echo "✅ Changes committed"
fi
echo ""

# Step 6: Check remote
echo "Step 6: Checking remote..."
REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REMOTE" ]; then
    echo "⚠️  No remote configured"
    echo ""
    echo "To add remote:"
    echo "  git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git"
    echo ""
    echo "Then push:"
    echo "  git push -u origin main"
else
    echo "✅ Remote configured: $REMOTE"
    echo ""
    echo "Ready to push! Run:"
    echo "  git push origin main"
fi
echo ""

echo "=========================================="
echo "✅ Repository Ready for GitHub!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review changes: git status"
echo "2. Push to GitHub: git push origin main"
echo ""
echo "If you need to create GitHub repo first:"
echo "  Go to: https://github.com/new"
echo "  Create repository: health-intelligence"
echo "  Then: git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git"
echo "  Then: git push -u origin main"
echo ""

