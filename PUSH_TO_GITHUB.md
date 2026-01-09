# Push to GitHub - Step by Step

Complete guide to push your code to GitHub.

## Step 1: Prepare Repository

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence

# Clean up unnecessary files
rm -f *.log backend.log frontend.log 2>/dev/null || true
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Verify .gitignore exists
if [ ! -f ".gitignore" ]; then
    echo "Error: .gitignore not found!"
    exit 1
fi

echo "✅ Repository cleaned"
```

## Step 2: Initialize Git (if needed)

```bash
# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
    echo "✅ Git initialized"
else
    echo "✅ Git already initialized"
fi
```

## Step 3: Add Files and Check for Secrets

```bash
# Add all files (respects .gitignore)
git add .

# Verify no secrets are being committed
echo "Checking for secrets..."
if git status | grep -E "\.env$|\.env\."; then
    echo "⚠️  WARNING: .env files found in git staging!"
    echo "   Remove them: git reset HEAD .env*"
    echo "   Make sure .env files are in .gitignore"
    exit 1
fi

echo "✅ No secrets found"
```

## Step 4: Commit Changes

```bash
# Commit
git commit -m "Initial commit - Health Intelligence Platform

- Multi-agent AI system for health data analytics
- FastAPI backend with LangGraph
- Next.js frontend with chat interface
- AWS Athena integration
- Tenant-safe queries with row-level security
- Production-ready configuration"

echo "✅ Changes committed"
```

## Step 5: Create GitHub Repository

1. **Go to GitHub**: https://github.com/new
2. **Repository settings**:
   - **Name**: `health-intelligence` (or your preferred name)
   - **Description**: `Health Intelligence Platform - Chat-based analytics for health data`
   - **Visibility**: 
     - **Public** (free, anyone can see code)
     - **Private** (paid, only you can see code) - **Recommended**
   - **DO NOT** check "Add a README file" (we have one)
   - **DO NOT** check "Add .gitignore" (we have one)
   - **DO NOT** check "Choose a license"
3. **Click "Create repository"**

## Step 6: Push to GitHub

```bash
# Add remote (REPLACE YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git

# Verify remote
git remote -v

# Push to GitHub
git push -u origin main
```

**If prompted for password**:
- Use a **Personal Access Token** (not your GitHub password)
- Create one at: https://github.com/settings/tokens
- Select scope: `repo`
- Use token as password

## Step 7: Verify Push

1. **Go to your GitHub repository**
2. **Verify files are uploaded**:
   - ✅ Backend code (`backend/`)
   - ✅ Frontend code (`frontend/`)
   - ✅ Documentation (`README.md`, etc.)
   - ✅ Configuration files (`render.yaml`, `Dockerfile`, etc.)
   - ❌ No `.env` files
   - ❌ No `venv/` or `node_modules/`

## Step 8: Update README (Optional)

If you want to update the repository URL in README:

```bash
# Replace YOUR_USERNAME with your actual GitHub username
sed -i '' 's/YOUR_USERNAME/your-actual-username/g' README.md

# Commit and push
git add README.md
git commit -m "Update README with correct repository URL"
git push origin main
```

## ✅ Success!

Your code is now on GitHub and ready for:
- Others to clone and use
- Deployment to Render or other platforms
- Collaboration and contributions
- Version control and backup

## 📋 Checklist

Before pushing, make sure:
- [x] All secrets are in `.gitignore`
- [x] No `.env` files are committed
- [x] `venv/` and `node_modules/` are excluded
- [x] Log files are cleaned
- [x] README.md is comprehensive
- [x] All necessary files are included

## 🔐 Security Reminder

**Important**: Never commit:
- `.env` files with real secrets
- AWS access keys
- OpenAI API keys
- JWT secrets
- Any credentials or tokens

All secrets should be:
- In `.gitignore`
- Set as environment variables
- Documented in `.env.example` files (with placeholder values)

---

**Your code is ready for GitHub! 🚀**

