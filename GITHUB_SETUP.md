# GitHub Setup & Render Deployment Guide

Complete step-by-step guide to push code to GitHub and deploy to Render.

## PART 1: Prepare Code for GitHub

### Step 1: Clean Repository

Run the cleanup script:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
chmod +x prepare_for_github.sh
./prepare_for_github.sh
```

This will:
- ✅ Remove log files
- ✅ Remove Python cache
- ✅ Check that venv/node_modules are excluded
- ✅ Verify .env files are excluded
- ✅ Create example .env files

### Step 2: Verify .gitignore

Make sure `.gitignore` exists and includes:
- `venv/`
- `node_modules/`
- `.env`
- `*.log`
- `__pycache__/`

### Step 3: Check for Secrets

**IMPORTANT**: Make sure no secrets are committed!

```bash
# Check for .env files (should not exist in git)
git status | grep -E "\.env$|\.env\."

# Check for AWS keys in code (should be empty)
grep -r "AKIA" --include="*.py" --include="*.js" --include="*.ts" . || echo "✅ No AWS keys in code"

# Check for OpenAI keys in code (should be empty)
grep -r "sk-" --include="*.py" --include="*.js" --include="*.ts" . || echo "✅ No OpenAI keys in code"
```

---

## PART 2: Initialize Git Repository

### Step 1: Initialize Git (if not already)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence

# Check if already a git repo
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already exists"
fi
```

### Step 2: Add Files

```bash
# Add all files (respecting .gitignore)
git add .

# Check what will be committed (verify no secrets!)
git status
```

**Verify**:
- ❌ No `.env` files
- ❌ No `venv/` directory
- ❌ No `node_modules/` directory
- ❌ No `*.log` files
- ✅ Only source code and configuration files

### Step 3: Commit

```bash
git commit -m "Initial commit - Health Intelligence Platform ready for Render deployment"
```

---

## PART 3: Create GitHub Repository

### Step 1: Create Repository on GitHub

1. **Go to GitHub**: https://github.com
2. **Login** to your account
3. **Click** the **"+"** icon → **"New repository"**
4. **Repository settings**:
   - **Name**: `health-intelligence` (or your preferred name)
   - **Description**: `Health Intelligence Platform - Chat-based analytics for health data`
   - **Visibility**: 
     - **Public** (free, anyone can see code)
     - **Private** (paid, only you can see code) - **Recommended for production**
   - **Initialize**: ❌ **DO NOT** check "Add a README" (we already have one)
   - **Add .gitignore**: ❌ **DO NOT** add (we already have one)
   - **Choose a license**: Optional

5. **Click "Create repository"**

### Step 2: Copy Repository URL

After creating, GitHub will show you the repository URL. It will look like:
- HTTPS: `https://github.com/yourusername/health-intelligence.git`
- SSH: `git@github.com:yourusername/health-intelligence.git`

**Copy the HTTPS URL** (easier for first-time setup)

---

## PART 4: Push Code to GitHub

### Step 1: Add Remote

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence

# Add GitHub remote (replace with your actual URL)
git remote add origin https://github.com/yourusername/health-intelligence.git

# Verify remote
git remote -v
```

### Step 2: Push to GitHub

```bash
# Push to main branch
git branch -M main
git push -u origin main
```

**If prompted for credentials**:
- **Username**: Your GitHub username
- **Password**: Use a **Personal Access Token** (not your GitHub password)

#### Create Personal Access Token (if needed)

If GitHub asks for a password, you need a Personal Access Token:

1. **Go to**: https://github.com/settings/tokens
2. **Click**: "Generate new token" → "Generate new token (classic)"
3. **Settings**:
   - **Note**: `Health Intelligence Deployment`
   - **Expiration**: Choose expiration (90 days recommended)
   - **Scopes**: Check `repo` (full control of private repositories)
4. **Click**: "Generate token"
5. **Copy the token** (you won't see it again!)
6. **Use this token as password** when pushing

### Step 3: Verify Push

1. **Refresh GitHub repository page**
2. **Verify files are uploaded**:
   - ✅ Backend code (`backend/`)
   - ✅ Frontend code (`frontend/`)
   - ✅ Documentation (`RENDER_DEPLOY.md`, etc.)
   - ✅ Configuration (`render.yaml`, `Dockerfile`, etc.)
   - ❌ No `.env` files
   - ❌ No `venv/` or `node_modules/`

---

## PART 5: Deploy to Render (Blueprint)

### Step 1: Login to Render

1. **Go to**: https://dashboard.render.com
2. **Sign up** (if new) or **Login** (if existing)
   - Can sign up with GitHub (recommended)

### Step 2: Create Blueprint

1. **Click**: **"New +"** → **"Blueprint"**
2. **Connect Repository**:
   - If signed up with GitHub: Select repository `health-intelligence`
   - If not: Click "Connect account" → Authorize GitHub → Select repository
3. **Render will detect** `render.yaml` automatically
4. **Review services**:
   - Backend service (Docker)
   - Frontend service (Node)
5. **Click**: **"Apply"**

### Step 3: Monitor Deployment

Render will start building both services:
- **Backend**: ~2-3 minutes (Docker build)
- **Frontend**: ~3-5 minutes (npm install + build)

**Watch logs** in Render dashboard to see progress.

### Step 4: Set Secrets (After First Deployment)

After services are created (even if build fails), you need to set secrets:

#### Backend Service → Environment Tab

Click on `health-intelligence-backend` service → **"Environment"** tab → **"Add Environment Variable"**

Add these variables one by one:

```bash
# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=AKIA... (your actual AWS access key)
AWS_SECRET_ACCESS_KEY=... (your actual AWS secret key)
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_PREFIX=athena-results/

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-... (your actual OpenAI API key)
OPENAI_MODEL=gpt-4

# JWT Configuration
JWT_SECRET=... (generate: openssl rand -hex 32)
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Server Configuration
HOST=0.0.0.0
DEBUG=false

# CORS Configuration (update after frontend deploys)
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com
```

**Important**: 
- Generate `JWT_SECRET` locally: `openssl rand -hex 32`
- Copy the output and use it as `JWT_SECRET`
- For `CORS_ORIGINS`, wait until frontend is deployed, then update with actual frontend URL

#### Frontend Service → Environment Tab

Click on `health-intelligence-frontend` service → **"Environment"** tab

**Note**: `NEXT_PUBLIC_API_URL` should be automatically set to backend URL by Blueprint. If not, add it manually:

```bash
NEXT_PUBLIC_API_URL=https://health-intelligence-backend.onrender.com
NODE_ENV=production
```

### Step 5: Update CORS After Frontend Deploys

1. **Get frontend URL**: Look at `health-intelligence-frontend` service → Copy URL (e.g., `https://health-intelligence-frontend.onrender.com`)
2. **Update backend CORS**: 
   - Go to `health-intelligence-backend` → Environment
   - Update `CORS_ORIGINS` with frontend URL
   - Click "Save Changes"
   - Backend will restart automatically

### Step 6: Verify Deployment

1. **Backend Health Check**:
   ```bash
   curl https://health-intelligence-backend.onrender.com/health
   ```
   Should return: `{"status":"healthy",...}`

2. **Frontend**:
   - Visit: `https://health-intelligence-frontend.onrender.com`
   - Should see login page

3. **Test Login**:
   - Enter username: `rajasaikatukuri`
   - Click Login
   - Should redirect to chat page

4. **Test API**:
   - Visit: `https://health-intelligence-backend.onrender.com/docs`
   - Should see FastAPI Swagger UI

---

## PART 6: Troubleshooting

### GitHub Push Issues

**Problem**: "Authentication failed"
```
Solution:
1. Use Personal Access Token instead of password
2. Create token: GitHub Settings → Developer settings → Personal access tokens
3. Use token as password when pushing
```

**Problem**: "Remote already exists"
```
Solution:
git remote remove origin
git remote add origin https://github.com/yourusername/health-intelligence.git
```

**Problem**: "Permission denied"
```
Solution:
1. Check repository is accessible (public or you have access to private)
2. Verify GitHub username is correct
3. Use HTTPS URL (not SSH) for first-time setup
```

### Render Deployment Issues

**Problem**: Build fails
```
Solution:
1. Check logs in Render dashboard
2. Verify all environment variables are set
3. Check Dockerfile path is correct
4. Verify render.yaml is valid
```

**Problem**: Backend can't connect to AWS
```
Solution:
1. Verify AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are correct
2. Check IAM user has permissions
3. Verify AWS_REGION matches your resources
```

**Problem**: Frontend can't connect to backend
```
Solution:
1. Verify NEXT_PUBLIC_API_URL is correct (https://)
2. Rebuild frontend after changing URL
3. Check backend is running and accessible
4. Verify CORS_ORIGINS includes frontend URL
```

---

## PART 7: Quick Reference

### Commands Summary

```bash
# 1. Clean repository
./prepare_for_github.sh

# 2. Initialize git (if needed)
git init

# 3. Add files
git add .

# 4. Commit
git commit -m "Initial commit - ready for Render"

# 5. Add remote (replace with your GitHub URL)
git remote add origin https://github.com/yourusername/health-intelligence.git

# 6. Push to GitHub
git push -u origin main
```

### After Deployment

```bash
# Test backend
curl https://your-backend.onrender.com/health

# Test frontend
curl https://your-frontend.onrender.com
```

### Update Code

```bash
# Make changes
# ...

# Commit
git add .
git commit -m "Update: description of changes"
git push origin main

# Render will automatically redeploy!
```

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] Code cleaned (no logs, cache, venv, node_modules)
- [ ] .gitignore created and verified
- [ ] No secrets in code
- [ ] Example .env files created

### GitHub Setup
- [ ] Git repository initialized
- [ ] Files added and committed
- [ ] GitHub repository created
- [ ] Remote added
- [ ] Code pushed to GitHub
- [ ] Verified files on GitHub

### Render Deployment
- [ ] Render account created/logged in
- [ ] Blueprint created from GitHub
- [ ] Services created (backend + frontend)
- [ ] Backend secrets set (AWS, OpenAI, JWT)
- [ ] Frontend environment variables set
- [ ] Both services deployed successfully
- [ ] CORS updated with frontend URL
- [ ] Health checks passing
- [ ] Tested login flow
- [ ] Tested chat functionality

---

## 🎉 Success!

Once all steps are complete:

1. ✅ Your code is on GitHub
2. ✅ Your app is live on Render
3. ✅ HTTPS enabled automatically
4. ✅ Public access enabled
5. ✅ Auto-deploy on git push enabled

**Your Health Intelligence Platform is now live!** 🚀

---

For detailed Render deployment guide, see: **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)**

For environment variables reference, see: **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)**

