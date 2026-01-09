# Render Deployment - Quick Summary

**Complete guide for deploying Health Intelligence Platform to Render.com**

## 📚 Documentation Files

1. **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Complete step-by-step deployment guide
2. **[RENDER_QUICK_START.md](./RENDER_QUICK_START.md)** - Fastest way to deploy (Blueprint)
3. **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)** - Complete environment variables reference

## 🚀 Quick Start (5 Minutes)

### Option 1: Blueprint Deployment (Easiest)

1. **Push code to GitHub**
   ```bash
   git add .
   git commit -m "Ready for Render"
   git push origin main
   ```

2. **Deploy on Render**
   - Go to https://dashboard.render.com
   - Click **"New +"** → **"Blueprint"**
   - Connect GitHub repo
   - Click **"Apply"**

3. **Set secrets** (in Render dashboard):
   - Backend → Environment → Add:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `OPENAI_API_KEY`
     - `JWT_SECRET` (generate: `openssl rand -hex 32`)
     - `CORS_ORIGINS` (set after frontend deploys)

4. **Wait for deployment** (~5-7 minutes)
5. **Test**: Visit frontend URL

**Done!** ✅

### Option 2: Manual Deployment

Follow detailed guide: **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)**

---

## 📋 Pre-Deployment Checklist

Before deploying, make sure you have:

- [ ] Render.com account (sign up at https://render.com)
- [ ] Code pushed to GitHub/GitLab/Bitbucket
- [ ] AWS credentials ready (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- [ ] OpenAI API key ready
- [ ] Generated JWT secret (`openssl rand -hex 32`)

---

## 🔑 Key Environment Variables

### Backend (Required)

```bash
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
OPENAI_API_KEY=sk-...
JWT_SECRET=... (32+ characters)
CORS_ORIGINS=https://your-frontend-url.onrender.com
DEBUG=false
```

### Frontend (Required)

```bash
NEXT_PUBLIC_API_URL=https://your-backend-url.onrender.com
NODE_ENV=production
```

**Full list**: See **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)**

---

## 🏗️ Architecture on Render

```
Internet (HTTPS)
    ↓
Render Load Balancer
    ↓
┌─────────────────────┬──────────────────────┐
│   Frontend          │   Backend             │
│   (Next.js)         │   (FastAPI)           │
│   Node Runtime      │   Docker Runtime      │
│   Port: 3000        │   Port: 8000          │
│   render.app        │   render.app          │
└─────────────────────┴──────────────────────┘
    ↓                          ↓
    Uses →              AWS Athena (S3)
```

---

## ✅ Features Included

- ✅ **HTTPS/SSL**: Automatic via Render (Let's Encrypt)
- ✅ **Health Checks**: Configured for both services
- ✅ **CORS**: Production-ready configuration
- ✅ **Environment Variables**: Secure secret management
- ✅ **Auto-Deploy**: Deploys on `git push`
- ✅ **Logs**: Real-time log streaming
- ✅ **Metrics**: CPU, memory, request rate monitoring
- ✅ **Scaling**: Easy to upgrade instances

---

## 🔧 Configuration Changes Made

### Backend (`backend/main.py`)

- ✅ Updated CORS to read from `CORS_ORIGINS` environment variable
- ✅ Port reads from `PORT` env var (provided by Render)
- ✅ Health check endpoint at `/health`
- ✅ Root endpoint at `/`

### Backend (`backend/config.py`)

- ✅ Port reads from `PORT` env var (with fallback to 8000)
- ✅ CORS origins from `CORS_ORIGINS` env var
- ✅ Production-ready defaults

### Frontend (`frontend/components/*`)

- ✅ Uses `NEXT_PUBLIC_API_URL` environment variable
- ✅ Already configured for production

---

## 🎯 Deployment Steps Summary

### Backend

1. Create Web Service on Render
2. Select: Docker runtime
3. Root directory: `health-intelligence/backend`
4. Health check: `/health`
5. Set environment variables
6. Deploy

### Frontend

1. Create Web Service on Render
2. Select: Node runtime
3. Root directory: `health-intelligence/frontend`
4. Build command: `npm install --legacy-peer-deps && npm run build`
5. Start command: `npm start`
6. Set `NEXT_PUBLIC_API_URL`
7. Deploy

### After Deployment

1. Update backend `CORS_ORIGINS` with frontend URL
2. Restart backend (automatic)
3. Test login flow
4. Verify HTTPS

---

## 🐛 Troubleshooting

### Backend Issues

**Problem**: Build fails
- Check logs in Render dashboard
- Verify all environment variables are set
- Check Dockerfile path is correct

**Problem**: Health check fails
- Verify `/health` endpoint returns 200 OK
- Check logs for errors
- Ensure service binds to `0.0.0.0:PORT`

**Problem**: CORS errors
- Update `CORS_ORIGINS` with exact frontend URL (https://)
- No trailing slashes
- Restart backend after changing

### Frontend Issues

**Problem**: Can't connect to backend
- Verify `NEXT_PUBLIC_API_URL` is correct (https://)
- Rebuild frontend after changing URL
- Check backend is running

**Problem**: Build fails
- Check build logs
- Verify Node.js version (18+)
- Check package.json dependencies

**Full troubleshooting**: See **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Part 5

---

## 📊 Post-Deployment

### Monitor Your Services

1. **Logs**: Dashboard → Service → Logs tab
2. **Metrics**: Dashboard → Service → Metrics tab
3. **Alerts**: Set up alerts for failures (paid plans)

### Test Your Deployment

```bash
# Backend health
curl https://your-backend.onrender.com/health

# Frontend
curl https://your-frontend.onrender.com
```

### Common Tasks

**Update environment variables**:
- Dashboard → Service → Environment → Edit → Save

**Manual deploy**:
- Dashboard → Service → Manual Deploy → Select branch/commit

**View logs**:
- Dashboard → Service → Logs tab

**Restart service**:
- Dashboard → Service → Manual Deploy → Deploy latest commit

---

## 🔒 Security Checklist

- [x] `DEBUG=false` in production
- [x] `JWT_SECRET` is secure random 32+ characters
- [x] `CORS_ORIGINS` specifies exact domains (not `*`)
- [x] All secrets in environment variables (not code)
- [x] HTTPS enabled (automatic on Render)
- [x] Health checks configured
- [x] No localhost references in production

---

## 📚 Next Steps

After successful deployment:

1. ✅ Test all functionality
2. 🔜 Add custom domain (optional)
3. 🔜 Set up monitoring/alerting
4. 🔜 Configure auto-scaling (if needed)
5. 🔜 Implement caching for better performance
6. 🔜 Set up CI/CD pipeline

---

## 📖 Detailed Guides

- **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Complete step-by-step guide
- **[RENDER_QUICK_START.md](./RENDER_QUICK_START.md)** - Blueprint deployment
- **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)** - Environment variables reference

---

## 🆘 Support

- **Render Docs**: https://render.com/docs
- **Render Community**: https://community.render.com
- **Render Status**: https://status.render.com

---

**Ready to deploy?** Start with **[RENDER_QUICK_START.md](./RENDER_QUICK_START.md)** for the fastest path!

**Need detailed steps?** Follow **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** for complete instructions!

