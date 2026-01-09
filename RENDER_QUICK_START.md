# Render.com Quick Start Guide

**Fastest way to deploy to Render using Blueprint (render.yaml)**

## Option 1: One-Click Blueprint Deployment (Easiest)

### Step 1: Push Code to GitHub

```bash
# If not already on GitHub
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
git init
git add .
git commit -m "Initial commit - ready for Render deployment"
git remote add origin https://github.com/yourusername/health-intelligence.git
git push -u origin main
```

### Step 2: Deploy from Blueprint

1. **Go to Render Dashboard**: https://dashboard.render.com
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub repository
4. Render will detect `render.yaml` automatically
5. Click **"Apply"**

### Step 3: Set Secrets

After services are created, go to each service and set:

**Backend Service** → **Environment**:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key  
- `OPENAI_API_KEY`: Your OpenAI API key
- `JWT_SECRET`: Generate with `openssl rand -hex 32` (or let Render generate)

**Frontend Service**:
- Already configured! `NEXT_PUBLIC_API_URL` is automatically set to backend URL

### Step 4: Wait for Deployment

- Backend builds first (~2-3 minutes)
- Frontend builds second (~3-5 minutes)
- Both services get HTTPS URLs automatically

### Step 5: Test

1. Backend: `https://health-intelligence-backend.onrender.com/health`
2. Frontend: `https://health-intelligence-frontend.onrender.com`

Done! ✅

---

## Option 2: Manual Step-by-Step

If you prefer manual setup, follow the detailed guide: **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)**

---

## Troubleshooting

**Build fails?**
- Check logs in Render dashboard
- Verify all environment variables are set
- Check Dockerfile paths are correct

**Frontend can't connect to backend?**
- Verify `NEXT_PUBLIC_API_URL` is set correctly
- Rebuild frontend after backend URL changes
- Check CORS_ORIGINS includes frontend URL

**CORS errors?**
- Update `CORS_ORIGINS` in backend with exact frontend URL (https://)
- Restart backend service

---

## What's Next?

- ✅ Your app is live with HTTPS!
- 🔜 Add custom domain (optional)
- 🔜 Set up monitoring
- 🔜 Configure auto-scaling

For detailed information, see **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)**

