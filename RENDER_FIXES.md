# Render Deployment Fixes

## Issues Fixed

### 1. Removed `dockerContext`
**Issue**: Some Render versions don't support `dockerContext` property
**Fix**: Removed `dockerContext: ./backend` from render.yaml
**Note**: Dockerfile will use default context (repository root), so paths adjusted

### 2. Updated Dockerfile CMD
**Issue**: Direct Python execution might not handle PORT env var correctly
**Fix**: Changed to use uvicorn command directly with PORT env var

### 3. Ensure Correct Paths
**Issue**: Dockerfile context might be different
**Fix**: Verify paths are relative to Dockerfile location

## Updated Files

### Backend Dockerfile
- ✅ Uses uvicorn command directly
- ✅ Handles PORT environment variable correctly
- ✅ Binds to 0.0.0.0 for Render

### render.yaml
- ✅ Removed `dockerContext` (may not be supported)
- ✅ Using `dockerfilePath` only
- ✅ Free tier configuration

## Next Steps

1. **Commit the fixes**:
   ```bash
   cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
   git add backend/Dockerfile render.yaml
   git commit -m "Fix Render deployment issues"
   git push origin main
   ```

2. **Try deploying again**:
   - Go to Render dashboard
   - Services should auto-redeploy from git push
   - Or manually trigger deployment

3. **Check logs** if it still fails:
   - Render dashboard → Service → Logs
   - Look for specific error messages
   - Share the error for more targeted fix

## If It Still Fails

**Check the actual error in Render logs** and share:
1. Which service failed (backend/frontend)
2. Error message from logs
3. Build step that failed

Then I can provide specific fixes!

## Alternative: Manual Service Creation

If Blueprint continues to fail, create services manually:

### Backend Manual Setup

1. Go to Render → New → Web Service
2. Connect GitHub repository
3. Settings:
   - **Name**: `health-intelligence-backend`
   - **Root Directory**: `health-intelligence/backend`
   - **Environment**: Docker
   - **Dockerfile Path**: `Dockerfile`
   - **Health Check Path**: `/health`
   - **Plan**: Free
4. Add environment variables (see RENDER_ENV_VARS.md)

### Frontend Manual Setup

1. Go to Render → New → Web Service
2. Connect GitHub repository
3. Settings:
   - **Name**: `health-intelligence-frontend`
   - **Root Directory**: `health-intelligence/frontend`
   - **Environment**: Node
   - **Build Command**: `npm install --legacy-peer-deps && npm run build`
   - **Start Command**: `npm start`
   - **Health Check Path**: `/`
   - **Plan**: Free
4. Add environment variables:
   - `NEXT_PUBLIC_API_URL` (set after backend deploys)
   - `NODE_ENV=production`

---

**Try deploying again with the fixes above. If it still fails, share the error logs!**

