# How to Check Render Deployment Errors

## Step 1: Get Error Logs from Render

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Click on the failed service** (e.g., `health-intelligence-backend`)
3. **Click "Logs" tab** (top menu)
4. **Check build logs** - scroll down to find errors
5. **Look for red error messages**

## Step 2: Common Error Patterns

### Backend Errors

**Error**: "dockerfilePath not found"
**Fix**: Check Dockerfile exists at `backend/Dockerfile`

**Error**: "No such file or directory: requirements.txt"
**Fix**: Dockerfile path issue - need to fix COPY paths

**Error**: "Port already in use"
**Fix**: Already fixed - using PORT env var ✅

**Error**: "ModuleNotFoundError: No module named '...'"
**Fix**: Check requirements.txt has all dependencies

**Error**: "Health check failed"
**Fix**: Ensure /health endpoint works

### Frontend Errors

**Error**: "npm install failed"
**Fix**: Check package.json exists and is valid

**Error**: "Build exceeded maximum time"
**Fix**: Free tier has time limits - may need upgrade

**Error**: "Out of memory"
**Fix**: Free tier has 512MB limit - may need upgrade

**Error**: "NEXT_PUBLIC_API_URL is undefined"
**Fix**: Set environment variable before build

## Step 3: Share Error Details

If deployment still fails, share:
1. **Which service failed**: Backend or Frontend?
2. **Exact error message**: Copy from Render logs
3. **Build step that failed**: What was the last successful step?

Then I can provide specific fixes!

## Quick Fixes Applied

✅ Removed `dockerContext` (may not be supported)
✅ Updated Dockerfile to use uvicorn directly
✅ Fixed Dockerfile COPY paths (since context is repo root)
✅ Using free tier

## Next Steps

1. **Commit the fixes**:
   ```bash
   cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
   git add backend/Dockerfile render.yaml
   git commit -m "Fix Render deployment - update Dockerfile paths"
   git push origin main
   ```

2. **Check Render logs** after push:
   - Services will auto-redeploy
   - Watch logs in Render dashboard
   - Look for specific errors

3. **If still fails, share error**:
   - Copy exact error from logs
   - I'll provide specific fix

---

**What's the exact error message you see in Render logs?**

