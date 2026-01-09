# Deploy to Render.com - Complete Guide

This guide walks you through deploying the Health Intelligence Platform to Render.com with HTTPS, proper CORS, and production-ready configuration.

## Prerequisites

- Render.com account (sign up at https://render.com - free tier available)
- GitHub repository with your code (or GitLab/Bitbucket)
- AWS credentials configured (for Athena access)
- OpenAI API key (for LLM)

## Architecture Overview

```
Internet (HTTPS)
    ↓
Render Load Balancer
    ↓
┌─────────────────────┬──────────────────────┐
│   Frontend          │   Backend            │
│   (Next.js)         │   (FastAPI)          │
│   Port: 3000        │   Port: 8000         │
│   render.app        │   render.app         │
└─────────────────────┴──────────────────────┘
    ↓                          ↓
    Uses →              AWS Athena (S3)
```

---

## PART 1: Deploy Backend (FastAPI)

### Step 1: Create New Web Service on Render

1. **Login to Render Dashboard**
   - Go to https://dashboard.render.com
   - Click **"New +"** → **"Web Service"**

2. **Connect Repository**
   - Select your Git provider (GitHub/GitLab/Bitbucket)
   - Choose repository: `health-intelligence`
   - Click **"Connect"**

3. **Configure Service**
   - **Name**: `health-intelligence-backend` (or your preferred name)
   - **Region**: Choose closest to your users (e.g., `Oregon (US West)`)
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: `health-intelligence/backend`
   - **Runtime**: `Docker`
   - **Dockerfile Path**: `Dockerfile` (relative to root directory: `backend/Dockerfile`)
   - **Instance Type**: 
     - **Free**: 512MB RAM (good for testing)
     - **Starter**: 1GB RAM (recommended for production)
     - **Standard**: 2GB+ RAM (for higher traffic)

### Step 2: Configure Environment Variables

Click **"Advanced"** → **"Environment Variables"** and add:

```bash
# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_PREFIX=athena-results/

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-actual-openai-api-key-here
OPENAI_MODEL=gpt-4

# JWT Configuration (IMPORTANT: Generate a secure random secret!)
JWT_SECRET=your-very-secure-random-secret-minimum-32-characters-long
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Server Configuration
HOST=0.0.0.0
DEBUG=false

# CORS Configuration (Update with your frontend URL after deploying frontend)
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com

# Render automatically provides PORT variable - no need to set it
```

**Important Notes:**
- **JWT_SECRET**: Generate a secure random string:
  ```bash
  # On your local machine:
  openssl rand -hex 32
  ```
  Copy the output and use it as `JWT_SECRET`

- **CORS_ORIGINS**: Initially use placeholder. After frontend is deployed, update this with the actual frontend URL (e.g., `https://your-frontend-name.onrender.com`)

- **AWS Credentials**: For better security on EC2, use IAM roles. For Render, use environment variables.

### Step 3: Configure Health Check

In the **"Health Check Path"** field, enter:
```
/health
```

This tells Render to check `https://your-backend-url.onrender.com/health` to verify the service is running.

### Step 4: Deploy

1. Click **"Create Web Service"**
2. Render will:
   - Clone your repository
   - Build Docker image from `backend/Dockerfile`
   - Start the container
   - Assign HTTPS URL (e.g., `https://health-intelligence-backend.onrender.com`)

3. **Monitor deployment**:
   - Watch logs in real-time
   - Wait for "Build successful" and "Your service is live"

4. **Test backend**:
   ```bash
   curl https://health-intelligence-backend.onrender.com/health
   ```
   Should return: `{"status":"healthy",...}`

### Step 5: Get Backend URL

After deployment, copy your backend URL:
```
https://health-intelligence-backend.onrender.com
```

You'll need this for the frontend configuration.

---

## PART 2: Deploy Frontend (Next.js)

### Step 1: Create New Web Service on Render

1. **In Render Dashboard**
   - Click **"New +"** → **"Web Service"**

2. **Connect Repository**
   - Select the same repository: `health-intelligence`
   - Click **"Connect"**

3. **Configure Service**
   - **Name**: `health-intelligence-frontend`
   - **Region**: Same as backend (for lower latency)
   - **Branch**: `main`
   - **Root Directory**: `health-intelligence/frontend`
   - **Runtime**: `Node`
   - **Build Command**: 
     ```bash
     npm install --legacy-peer-deps && npm run build
     ```
   - **Start Command**: 
     ```bash
     npm start
     ```
   - **Instance Type**: Same as backend (Free/Starter/Standard)

### Step 2: Configure Environment Variables

Add these environment variables:

```bash
# Backend API URL (from Part 1)
NEXT_PUBLIC_API_URL=https://health-intelligence-backend.onrender.com

# Node Environment
NODE_ENV=production
```

**Important**: 
- `NEXT_PUBLIC_API_URL` must start with `https://` (not `http://`)
- Use the exact backend URL from Part 1
- This variable is used at **build time** by Next.js

### Step 3: Configure Health Check

**Health Check Path**: Leave empty (or use `/`)

Next.js automatically handles the root route, so Render will check `https://your-frontend-url.onrender.com/` to verify it's running.

### Step 4: Deploy

1. Click **"Create Web Service"**
2. Render will:
   - Install dependencies (`npm install`)
   - Build Next.js app (`npm run build`) - **this is when `NEXT_PUBLIC_API_URL` is baked in**
   - Start the server (`npm start`)
   - Assign HTTPS URL

3. **Monitor deployment**:
   - Build can take 3-5 minutes
   - Watch for "Build successful"

4. **Test frontend**:
   - Visit `https://health-intelligence-frontend.onrender.com`
   - Should see the login page

### Step 5: Update Backend CORS

**Now that frontend is deployed, update backend CORS:**

1. Go to backend service in Render dashboard
2. Go to **"Environment"** tab
3. Update `CORS_ORIGINS`:
   ```bash
   CORS_ORIGINS=https://health-intelligence-frontend.onrender.com
   ```
4. Click **"Save Changes"**
5. Render will automatically restart the backend

**If you have multiple environments or domains:**
```bash
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com,https://your-custom-domain.com
```

---

## PART 3: Custom Domain (Optional)

### Add Custom Domain to Frontend

1. In Render dashboard → Frontend service
2. Go to **"Settings"** → **"Custom Domains"**
3. Click **"Add Custom Domain"**
4. Enter your domain: `app.yourdomain.com`
5. Render will provide DNS records (CNAME)
6. Add DNS records in your domain registrar:
   ```
   Type: CNAME
   Name: app
   Value: [provided-by-render]
   ```
7. Render will provision SSL automatically via Let's Encrypt

### Update Environment Variables

After custom domain is active:

1. **Frontend**: Update `NEXT_PUBLIC_API_URL` (if using custom domain for backend)
2. **Backend**: Update `CORS_ORIGINS` with custom domain:
   ```bash
   CORS_ORIGINS=https://app.yourdomain.com
   ```

---

## PART 4: Production Best Practices

### ✅ Security Checklist

- [x] **JWT_SECRET**: Using secure random 32+ character string
- [x] **DEBUG**: Set to `false` in production
- [x] **CORS_ORIGINS**: Specific domains, not `*`
- [x] **HTTPS Only**: Render provides this automatically
- [x] **Environment Variables**: All secrets stored in Render (not in code)
- [x] **Health Checks**: Configured for both services

### 🔧 Performance Optimization

1. **Enable Auto-Deploy** (default):
   - Services auto-deploy on `git push` to `main`
   - Disable if you want manual control

2. **Render Automatic HTTPS**:
   - SSL certificates auto-renewed
   - No manual certificate management needed

3. **Instance Sizing**:
   - **Free tier**: 512MB RAM, spins down after 15min inactivity
   - **Starter**: $7/month, 1GB RAM, always on
   - **Standard**: $25/month, 2GB RAM, better for production

### 📊 Monitoring

1. **View Logs**:
   - Render dashboard → Service → **"Logs"** tab
   - Real-time log streaming
   - Historical logs available

2. **Metrics**:
   - CPU usage
   - Memory usage
   - Request rate
   - Response times

3. **Alerts** (Paid plans):
   - Set up alerts for service failures
   - Email/Slack notifications

### 🔄 Continuous Deployment

1. **Auto-Deploy Enabled** (default):
   ```bash
   git add .
   git commit -m "Update code"
   git push origin main
   ```
   Render automatically deploys

2. **Manual Deploy**:
   - Dashboard → Service → **"Manual Deploy"**
   - Choose branch/commit

---

## PART 5: Troubleshooting

### Backend Issues

**Problem**: Backend fails to start
```
Solution:
1. Check logs in Render dashboard
2. Verify all environment variables are set
3. Check AWS credentials are correct
4. Verify PORT is not manually set (Render provides it)
```

**Problem**: Health check fails
```
Solution:
1. Verify /health endpoint returns 200 OK
2. Check logs for errors
3. Ensure service is binding to 0.0.0.0:PORT (not 127.0.0.1)
```

**Problem**: CORS errors in browser
```
Solution:
1. Check CORS_ORIGINS includes exact frontend URL (with https://)
2. No trailing slashes in CORS_ORIGINS
3. Update backend environment variable and restart
```

### Frontend Issues

**Problem**: Frontend can't connect to backend
```
Solution:
1. Verify NEXT_PUBLIC_API_URL is correct (with https://)
2. Check backend is running and accessible
3. Rebuild frontend after changing NEXT_PUBLIC_API_URL (it's baked at build time)
```

**Problem**: Frontend shows "Cannot connect to backend"
```
Solution:
1. Test backend URL manually: curl https://backend-url.onrender.com/health
2. Check browser console for actual error
3. Verify CORS is configured correctly
```

**Problem**: Build fails
```
Solution:
1. Check build logs for specific error
2. Verify Node.js version (should be 18+)
3. Check package.json dependencies
4. Try: npm install --legacy-peer-deps
```

### General Issues

**Problem**: Service keeps restarting
```
Solution:
1. Check logs for crash errors
2. Verify health check path is correct
3. Check memory usage (might need larger instance)
4. Review application code for unhandled exceptions
```

**Problem**: Slow response times
```
Solution:
1. Upgrade instance type (more RAM/CPU)
2. Check AWS Athena query performance
3. Enable caching if applicable
4. Review database/API query optimization
```

---

## PART 6: Environment Variables Reference

### Backend Environment Variables

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `AWS_REGION` | Yes | `us-east-2` | AWS region for Athena |
| `AWS_ACCESS_KEY_ID` | Yes | `AKIA...` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Yes | `...` | AWS secret key |
| `ATHENA_DATABASE` | Yes | `health_data_lake` | Athena database name |
| `ATHENA_WORKGROUP` | Yes | `health-data-tenant-queries` | Athena workgroup |
| `S3_BUCKET` | Yes | `health-data-lake-...` | S3 bucket name |
| `OPENAI_API_KEY` | Yes | `sk-...` | OpenAI API key |
| `OPENAI_MODEL` | Yes | `gpt-4` | OpenAI model |
| `LLM_PROVIDER` | Yes | `openai` | LLM provider |
| `JWT_SECRET` | Yes | `random-hex-32` | JWT signing secret |
| `JWT_ALGORITHM` | No | `HS256` | JWT algorithm (default: HS256) |
| `JWT_EXPIRATION_HOURS` | No | `24` | JWT expiry (default: 24) |
| `CORS_ORIGINS` | Yes | `https://frontend.onrender.com` | Allowed CORS origins |
| `DEBUG` | No | `false` | Debug mode (default: false) |
| `PORT` | No | (Auto) | Port (provided by Render) |
| `HOST` | No | `0.0.0.0` | Host (default: 0.0.0.0) |

### Frontend Environment Variables

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `NEXT_PUBLIC_API_URL` | Yes | `https://backend.onrender.com` | Backend API URL |
| `NODE_ENV` | No | `production` | Node environment |

**Note**: Variables starting with `NEXT_PUBLIC_` are exposed to the browser. Never put secrets here!

---

## PART 7: Quick Deployment Checklist

### Before Deployment
- [ ] Code pushed to Git repository
- [ ] AWS credentials ready
- [ ] OpenAI API key ready
- [ ] JWT_SECRET generated (`openssl rand -hex 32`)

### Backend Deployment
- [ ] Created Web Service on Render
- [ ] Set root directory: `health-intelligence/backend`
- [ ] Selected Docker runtime
- [ ] Added all environment variables
- [ ] Set health check path: `/health`
- [ ] Deployment successful
- [ ] Health check passing
- [ ] Backend URL copied

### Frontend Deployment
- [ ] Created Web Service on Render
- [ ] Set root directory: `health-intelligence/frontend`
- [ ] Selected Node runtime
- [ ] Set build command: `npm install --legacy-peer-deps && npm run build`
- [ ] Set start command: `npm start`
- [ ] Added `NEXT_PUBLIC_API_URL` environment variable
- [ ] Deployment successful
- [ ] Frontend URL copied

### After Deployment
- [ ] Updated backend `CORS_ORIGINS` with frontend URL
- [ ] Backend restarted automatically
- [ ] Tested login flow
- [ ] Tested chat functionality
- [ ] Verified HTTPS is working
- [ ] Checked browser console for errors

---

## PART 8: Testing Your Deployment

### 1. Test Backend Health
```bash
curl https://your-backend.onrender.com/health
```
Expected: `{"status":"healthy",...}`

### 2. Test Backend API Docs
Visit: `https://your-backend.onrender.com/docs`
Should show: FastAPI Swagger UI

### 3. Test Frontend
Visit: `https://your-frontend.onrender.com`
Should show: Login page

### 4. Test Login Flow
1. Enter username: `rajasaikatukuri`
2. Click Login
3. Should redirect to chat page

### 5. Test API Call from Frontend
1. Open browser DevTools (F12)
2. Go to Network tab
3. Try to login
4. Check for successful API calls to backend
5. Verify no CORS errors

### 6. Test Chat
1. After login, try a query: "Summarize my last 30 days"
2. Check backend logs in Render
3. Verify response comes back

---

## Support & Resources

- **Render Docs**: https://render.com/docs
- **Render Status**: https://status.render.com
- **Render Community**: https://community.render.com

## Next Steps

1. ✅ Both services deployed and working
2. 🔜 Set up custom domain (optional)
3. 🔜 Configure monitoring/alerting
4. 🔜 Set up auto-scaling (if needed)
5. 🔜 Implement caching for better performance

---

**Congratulations! Your Health Intelligence Platform is now live on Render with HTTPS! 🎉**

