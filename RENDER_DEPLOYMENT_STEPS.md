# Render Deployment - Exact Steps

**Complete step-by-step guide to deploy to Render.com**

---

## ✅ Step 1: Prepare Code for GitHub

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence

# Clean logs and cache
rm -f *.log backend.log frontend.log 2>/dev/null || true
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true

# Initialize git (if needed)
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Add files (respects .gitignore)
git add .

# Verify no secrets
git status | grep "\.env$" && echo "⚠️ WARNING: .env files found!" || echo "✅ No .env files"

# Commit
git commit -m "Initial commit - Health Intelligence Platform ready for Render"
```

---

## ✅ Step 2: Push to GitHub

### A. Create GitHub Repository

1. Go to: **https://github.com/new**
2. Settings:
   - **Name**: `health-intelligence`
   - **Visibility**: **Private** (recommended) or Public
   - ❌ **DO NOT** check "Add README" (we have one)
   - ❌ **DO NOT** add .gitignore (we have one)
3. Click **"Create repository"**

### B. Push Code

```bash
# Add remote (REPLACE YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git

# Push (use Personal Access Token as password if prompted)
git push -u origin main
```

**Need Personal Access Token?**
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scope: `repo`
4. Generate and copy token
5. Use token as password when pushing

---

## ✅ Step 3: Deploy to Render (Blueprint)

### A. Login to Render

1. Go to: **https://dashboard.render.com**
2. **Sign up** (or Login)
   - **Best**: Sign up with GitHub (one-click connection)

### B. Create Blueprint

1. Click **"New +"** → **"Blueprint"**
2. **Connect Repository**:
   - Select `health-intelligence` repository
   - If not visible: Click "Connect account" → Authorize GitHub
3. Render automatically detects `render.yaml`
4. Review services:
   - ✅ Backend (Docker)
   - ✅ Frontend (Node)
5. Click **"Apply"**

### C. Wait for Initial Build

- Backend: ~2-3 minutes
- Frontend: ~3-5 minutes
- ⚠️ **First build may fail** - that's OK! We need to add secrets.

---

## ✅ Step 4: Set Secrets in Render

**After services are created**, go to each service → **"Environment"** tab

### Backend Service Secrets

Go to: **`health-intelligence-backend`** service → **"Environment"** tab

**First, generate JWT secret locally:**

```bash
openssl rand -hex 32
```

Copy the output - you'll need it as `JWT_SECRET`

**Then add these environment variables in Render:**

Click **"Add Environment Variable"** for each:

```bash
# Copy-paste these values exactly:

AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_PREFIX=athena-results/
LLM_PROVIDER=openai
OPENAI_MODEL=gpt-4
HOST=0.0.0.0
DEBUG=false
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com
```

**Then add these with YOUR actual values:**

```bash
AWS_ACCESS_KEY_ID=AKIA... (your actual AWS access key)
AWS_SECRET_ACCESS_KEY=... (your actual AWS secret key)
OPENAI_API_KEY=sk-... (your actual OpenAI API key)
JWT_SECRET=... (paste the output from openssl rand -hex 32)
```

**Important Notes:**
- For `CORS_ORIGINS`, use the **actual frontend URL** from Render dashboard (it will be something like `https://health-intelligence-frontend-xyz.onrender.com`)
- If frontend isn't deployed yet, set it temporarily, then **update after frontend deploys**

### Frontend Service Secrets

Go to: **`health-intelligence-frontend`** service → **"Environment"** tab

**Update `NEXT_PUBLIC_API_URL` with actual backend URL:**

1. Get backend URL from Render dashboard (look at `health-intelligence-backend` service)
2. Add/Update environment variable:

```bash
NEXT_PUBLIC_API_URL=https://health-intelligence-backend-xyz.onrender.com
NODE_ENV=production
```

**Important**: 
- Replace `xyz` with your actual backend URL
- Must start with `https://`
- No trailing slash

### Update CORS After Frontend Deploys

1. Get frontend URL from Render dashboard
2. Go to backend service → Environment
3. Update `CORS_ORIGINS` with exact frontend URL
4. Click "Save Changes"
5. Backend restarts automatically

---

## ✅ Step 5: Test Deployment

### A. Test Backend

```bash
# Replace with your actual backend URL
curl https://health-intelligence-backend-xyz.onrender.com/health
```

**Expected**: `{"status":"healthy",...}`

### B. Test Frontend

Visit: `https://health-intelligence-frontend-xyz.onrender.com`

**Expected**: Login page

### C. Test Login

1. Enter username: `rajasaikatukuri`
2. Click Login
3. Should redirect to chat page

### D. Test API Docs

Visit: `https://health-intelligence-backend-xyz.onrender.com/docs`

**Expected**: FastAPI Swagger UI

---

## 🎉 Success!

Your app is now:
- ✅ Live on Render
- ✅ Publicly accessible
- ✅ HTTPS enabled automatically
- ✅ Auto-deploys on git push

---

## 🔄 Update Code Later

When you make changes:

```bash
git add .
git commit -m "Update: description"
git push origin main
```

Render automatically redeploys! 🚀

---

## 🐛 Troubleshooting

### Build Fails

**Check**:
1. Render logs dashboard
2. All environment variables are set
3. Dockerfile path is correct (`backend/Dockerfile`)
4. Build command is correct

### Backend Can't Connect to AWS

**Check**:
1. `AWS_ACCESS_KEY_ID` is correct
2. `AWS_SECRET_ACCESS_KEY` is correct
3. IAM user has permissions
4. `AWS_REGION` matches your resources

### Frontend Can't Connect to Backend

**Check**:
1. `NEXT_PUBLIC_API_URL` is correct (https://)
2. Backend is running
3. Rebuild frontend after changing URL (it's baked at build time)

### CORS Errors

**Check**:
1. `CORS_ORIGINS` includes exact frontend URL (https://)
2. No trailing slash
3. Backend restarted after changing CORS_ORIGINS

---

## 📋 Complete Environment Variables Checklist

### Backend (Required)

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
OPENAI_API_KEY=sk-... (your actual key)
OPENAI_MODEL=gpt-4
JWT_SECRET=... (generate: openssl rand -hex 32)
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
HOST=0.0.0.0
DEBUG=false
CORS_ORIGINS=https://health-intelligence-frontend-xyz.onrender.com
```

### Frontend (Required)

```bash
NEXT_PUBLIC_API_URL=https://health-intelligence-backend-xyz.onrender.com
NODE_ENV=production
```

---

## 📚 Additional Resources

- **[GITHUB_SETUP.md](./GITHUB_SETUP.md)** - Detailed GitHub setup
- **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Complete Render guide
- **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)** - Environment variables reference
- **[DEPLOY_TO_RENDER.md](./DEPLOY_TO_RENDER.md)** - Quick 5-step guide

---

**Ready to deploy?** Start with Step 1! 🚀

