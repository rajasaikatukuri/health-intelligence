# Quick Deploy Steps - Render.com

**Fast 5-step guide to deploy your app to Render**

---

## ✅ Step 1: Clean Code

Run this command in your terminal:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
chmod +x prepare_for_github.sh
./prepare_for_github.sh
```

✅ Logs cleaned
✅ Cache cleaned
✅ Ready for GitHub

---

## ✅ Step 2: Push to GitHub

### A. Initialize Git & Commit

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence

# Check if git is initialized
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Add files (respects .gitignore)
git add .

# Verify no secrets are being committed
git status | grep -E "\.env$" && echo "⚠️ WARNING: .env files found!" || echo "✅ No .env files in git"

# Commit
git commit -m "Initial commit - Health Intelligence Platform ready for Render"
```

### B. Create GitHub Repository

1. Go to: **https://github.com**
2. Click **"+"** → **"New repository"**
3. Settings:
   - **Name**: `health-intelligence`
   - **Visibility**: **Private** (recommended) or Public
   - **DO NOT** check "Add README" (we have one)
   - **DO NOT** add .gitignore (we have one)
4. Click **"Create repository"**

### C. Push Code

```bash
# Add remote (REPLACE YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/health-intelligence.git

# Push (use Personal Access Token as password if prompted)
git push -u origin main
```

**Need a Personal Access Token?**
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
   - Select `health-intelligence`
   - If not visible: Click "Connect account" → Authorize GitHub
3. Render automatically detects `render.yaml`
4. Review services:
   - ✅ Backend (Docker)
   - ✅ Frontend (Node)
5. Click **"Apply"**

### C. Wait for Build

- ⏳ Backend: ~2-3 minutes
- ⏳ Frontend: ~3-5 minutes
- ⚠️ First build may fail (need secrets) - that's OK!

---

## ✅ Step 4: Set Secrets in Render

### A. Generate JWT Secret (Do This First)

Run this on your local machine:

```bash
openssl rand -hex 32
```

**Copy the output** - you'll need it as `JWT_SECRET`

### B. Set Backend Secrets

Go to: **`health-intelligence-backend`** service → **"Environment"** tab

Click **"Add Environment Variable"** for each:

```bash
# Copy-paste these one by one:

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
```

**Then add these with YOUR actual values:**

```bash
AWS_ACCESS_KEY_ID=AKIA... (your actual AWS access key)
AWS_SECRET_ACCESS_KEY=... (your actual AWS secret key)
OPENAI_API_KEY=sk-... (your actual OpenAI API key)
JWT_SECRET=... (paste the output from openssl rand -hex 32)
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com
```

**Important**: 
- For `CORS_ORIGINS`, use the actual frontend URL from Render dashboard
- If frontend isn't deployed yet, set it temporarily, then update after frontend deploys

### C. Set Frontend Secrets

Go to: **`health-intelligence-frontend`** service → **"Environment"** tab

**Usually auto-set by Blueprint**, but verify:

```bash
NEXT_PUBLIC_API_URL=https://health-intelligence-backend.onrender.com
NODE_ENV=production
```

If not set, add it manually with the actual backend URL from Render dashboard.

### D. Update CORS (After Frontend Deploys)

1. Get frontend URL from Render dashboard (look at `health-intelligence-frontend` service)
2. Go to backend service → Environment
3. Update `CORS_ORIGINS` with exact frontend URL (must start with `https://`)
4. Click "Save Changes"
5. Backend restarts automatically

---

## ✅ Step 5: Test Deployment

### A. Test Backend

```bash
# Replace with your actual backend URL
curl https://health-intelligence-backend.onrender.com/health
```

Expected: `{"status":"healthy",...}`

### B. Test Frontend

Visit: `https://health-intelligence-frontend.onrender.com` (replace with your URL)

Expected: Login page

### C. Test Login

1. Enter username: `rajasaikatukuri`
2. Click Login
3. Should redirect to chat page

### D. Test API Docs

Visit: `https://health-intelligence-backend.onrender.com/docs`

Expected: FastAPI Swagger UI

---

## 🎉 Success!

Your app is now:
- ✅ Live on Render
- ✅ Publicly accessible
- ✅ HTTPS enabled automatically
- ✅ Auto-deploys on git push

---

## 🔄 Update Code

When you make changes:

```bash
git add .
git commit -m "Update: description"
git push origin main
```

Render automatically redeploys! 🚀

---

## 🐛 Common Issues

**Build fails?**
→ Check Render logs → Verify all secrets are set → Check environment variables

**Frontend can't connect?**
→ Verify `NEXT_PUBLIC_API_URL` is correct (https://) → Rebuild frontend

**CORS errors?**
→ Update `CORS_ORIGINS` with exact frontend URL (https://) → Restart backend

---

## 📚 Need More Details?

- **[GITHUB_SETUP.md](./GITHUB_SETUP.md)** - Detailed GitHub setup
- **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Complete Render guide
- **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)** - All environment variables

---

**Ready?** Start with Step 1! 🚀

