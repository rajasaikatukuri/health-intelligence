# Quick Guide: Deploy to Render in 5 Steps

**Fastest way to deploy Health Intelligence Platform to Render.com**

---

## Step 1: Clean & Prepare Code ✅

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
chmod +x prepare_for_github.sh
./prepare_for_github.sh
```

This cleans:
- ✅ Log files
- ✅ Python cache
- ✅ Temporary files
- ✅ Creates example .env files

---

## Step 2: Push to GitHub ✅

### 2.1: Initialize Git (if needed)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence

# Check if already a git repo
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Add all files
git add .

# Commit
git commit -m "Initial commit - Health Intelligence Platform ready for Render"
```

### 2.2: Create GitHub Repository

1. Go to: https://github.com
2. Click **"+"** → **"New repository"**
3. **Settings**:
   - **Name**: `health-intelligence`
   - **Visibility**: Private (recommended) or Public
   - **DO NOT** check "Initialize with README" (we have one)
4. Click **"Create repository"**

### 2.3: Push to GitHub

```bash
# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git

# Push
git push -u origin main
```

**If asked for password**: Use a **Personal Access Token** (not your GitHub password)

**To create token**:
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scope: `repo`
4. Copy token and use as password

---

## Step 3: Deploy to Render (Blueprint) ✅

### 3.1: Login to Render

1. Go to: https://dashboard.render.com
2. **Sign up** (or Login if existing)
   - **Recommended**: Sign up with GitHub (one-click connection)

### 3.2: Create Blueprint

1. Click **"New +"** → **"Blueprint"**
2. **Connect Repository**:
   - Select `health-intelligence` repository
   - If not visible: Click "Connect account" → Authorize GitHub
3. **Render detects `render.yaml` automatically**
4. **Review**:
   - ✅ Backend service (Docker)
   - ✅ Frontend service (Node)
5. Click **"Apply"**

### 3.3: Wait for Initial Build

- Backend: ~2-3 minutes
- Frontend: ~3-5 minutes
- **Don't worry if first build fails** - we need to add secrets!

---

## Step 4: Set Secrets in Render ✅

**After services are created**, go to each service and add secrets:

### Backend Service Secrets

Go to: `health-intelligence-backend` → **"Environment"** tab

Add these variables (click "Add Environment Variable" for each):

```bash
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=AKIA... (your actual key)
AWS_SECRET_ACCESS_KEY=... (your actual secret)
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_PREFIX=athena-results/
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-... (your actual OpenAI key)
OPENAI_MODEL=gpt-4
JWT_SECRET=... (generate with: openssl rand -hex 32)
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
HOST=0.0.0.0
DEBUG=false
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com
```

**Generate JWT_SECRET**:
```bash
openssl rand -hex 32
```
Copy the output and use as `JWT_SECRET`.

**Note**: For `CORS_ORIGINS`, wait until frontend deploys, then update with actual URL.

### Frontend Service Secrets

Go to: `health-intelligence-frontend` → **"Environment"** tab

**Usually auto-configured by Blueprint**, but verify:
```bash
NEXT_PUBLIC_API_URL=https://health-intelligence-backend.onrender.com
NODE_ENV=production
```

If not set, add it manually.

### 4.4: Update CORS After Frontend Deploys

1. Get frontend URL from Render dashboard (e.g., `https://health-intelligence-frontend-xyz.onrender.com`)
2. Go to backend service → Environment
3. Update `CORS_ORIGINS` with exact frontend URL (with `https://`)
4. Click "Save Changes"
5. Backend restarts automatically

---

## Step 5: Test Deployment ✅

### 5.1: Test Backend

```bash
curl https://health-intelligence-backend.onrender.com/health
```

Should return: `{"status":"healthy",...}`

### 5.2: Test Frontend

Visit: `https://health-intelligence-frontend.onrender.com`

Should see: Login page

### 5.3: Test Login

1. Enter username: `rajasaikatukuri`
2. Click Login
3. Should redirect to chat page

### 5.4: Test API Docs

Visit: `https://health-intelligence-backend.onrender.com/docs`

Should see: FastAPI Swagger UI

---

## 🎉 Done!

Your Health Intelligence Platform is now:
- ✅ Live on Render
- ✅ Publicly accessible
- ✅ HTTPS enabled
- ✅ Auto-deploys on git push

---

## 🔄 Update Code

To update code:

```bash
# Make changes
# ...

# Commit and push
git add .
git commit -m "Update: description"
git push origin main

# Render automatically redeploys! 🚀
```

---

## 🐛 Troubleshooting

**Build fails?**
- Check logs in Render dashboard
- Verify all secrets are set
- Check environment variables are correct

**Frontend can't connect?**
- Verify `NEXT_PUBLIC_API_URL` is correct
- Rebuild frontend after changing URL
- Check backend is running

**CORS errors?**
- Update `CORS_ORIGINS` with exact frontend URL (https://)
- Restart backend after changing

---

## 📚 Detailed Guides

- **[GITHUB_SETUP.md](./GITHUB_SETUP.md)** - Detailed GitHub setup
- **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Complete Render deployment guide
- **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)** - Environment variables reference

---

**Need help?** Check the detailed guides above! 🚀

