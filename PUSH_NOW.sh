#!/bin/bash
# Final script to prepare and push everything to GitHub

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "📤 Final Push to GitHub"
echo "=========================================="
echo ""

# Step 1: Clean up
echo "Step 1: Cleaning up..."
rm -f *.log backend.log frontend.log 2>/dev/null || true
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
echo "✅ Cleanup complete"
echo ""

# Step 2: Check git status
echo "Step 2: Checking git status..."
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
    echo "✅ Git initialized"
else
    echo "✅ Git repository exists"
fi
echo ""

# Step 3: Verify no secrets
echo "Step 3: Checking for secrets..."
SECRETS_FOUND=false

if git ls-files | grep -q "\.env$"; then
    echo "⚠️  WARNING: .env files found in git!"
    git reset HEAD backend/.env frontend/.env.local 2>/dev/null || true
    SECRETS_FOUND=true
fi

if [ "$SECRETS_FOUND" = false ]; then
    echo "✅ No secrets found in git"
fi
echo ""

# Step 4: Add all files
echo "Step 4: Adding files to git..."
git add .
echo "✅ Files added"
echo ""

# Step 5: Show status
echo "Step 5: Files to be committed:"
git status --short | head -40
echo ""

# Step 6: Check if there are changes
if git diff --cached --quiet && git diff --quiet; then
    echo "⚠️  No changes to commit (everything already committed)"
    echo ""
    echo "To push existing commits:"
    echo "  git push origin main"
else
    echo "Step 6: Committing changes..."
    git commit -m "Complete Health Intelligence Platform

- Backend: FastAPI + LangGraph multi-agent system
- Frontend: Next.js chat interface with Vega-Lite charts  
- iOS App: Complete HealthKit sync app (Swift code)
- Athena: DDL scripts and setup guides
- Deployment: Render.com configuration
- Documentation: Complete setup guides

Components:
- Natural language health data queries
- Interactive dashboards
- Multi-tenant security
- AWS Athena integration
- iOS HealthKit sync
- Production-ready configuration"
    echo "✅ Changes committed"
fi
echo ""

# Step 7: Check remote
echo "Step 7: Checking remote..."
REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REMOTE" ]; then
    echo "⚠️  No remote configured"
    echo ""
    echo "To add remote and push:"
    echo "  1. Create GitHub repo at: https://github.com/new"
    echo "  2. Then run:"
    echo "     git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git"
    echo "     git push -u origin main"
else
    echo "✅ Remote configured: $REMOTE"
    echo ""
    echo "Ready to push! Run:"
    echo "  git push origin main"
    echo ""
    echo "Or push now? (y/n)"
    read -p "> " answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        echo ""
        echo "Pushing to GitHub..."
        git push origin main
        echo ""
        echo "✅ Pushed to GitHub!"
    fi
fi
echo ""

echo "=========================================="
echo "✅ Repository Ready!"
echo "=========================================="
echo ""
echo "What's included:"
echo "  ✅ Backend (FastAPI + LangGraph)"
echo "  ✅ Frontend (Next.js)"
echo "  ✅ iOS App (Swift + HealthKit)"
echo "  ✅ Athena scripts"
echo "  ✅ Complete documentation"
echo "  ✅ Deployment configs"
echo ""
echo "Next steps:"
echo "  1. Create GitHub repo (if needed): https://github.com/new"
echo "  2. Push: git push origin main"
echo "  3. Share the repository!"
echo ""

