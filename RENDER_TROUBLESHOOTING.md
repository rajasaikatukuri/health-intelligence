# Render Deployment Troubleshooting

## Common Deployment Failures & Fixes

### Backend Deployment Failures

#### Issue 1: Docker Build Fails
**Possible causes:**
- Dockerfile path incorrect
- Missing files in Docker context
- Dependencies fail to install

**Solution:**
Check Dockerfile is at `./backend/Dockerfile` and context is `./backend`

#### Issue 2: Port Binding Error
**Error**: "Port already in use" or "Failed to bind to port"
**Solution**: Backend should use `0.0.0.0:PORT` (already configured ✅)

#### Issue 3: Health Check Fails
**Error**: Health check endpoint not responding
**Solution**: 
- Ensure `/health` endpoint returns 200 OK
- Health check path is set to `/health` ✅

#### Issue 4: Missing Environment Variables
**Error**: "Missing required environment variables"
**Solution**: 
- Add all required env vars in Render dashboard
- Check `config.py` for required variables

#### Issue 5: Python Dependencies Fail
**Error**: "ERROR: Could not find a version that satisfies the requirement"
**Solution**:
- Check `requirements.txt` versions
- May need to pin specific versions

### Frontend Deployment Failures

#### Issue 1: Build Command Fails
**Error**: "npm install failed" or "npm run build failed"
**Possible causes:**
- Missing `package.json`
- Dependency conflicts
- Out of memory during build

**Solution**:
- Verify `package.json` exists
- Build command: `npm install --legacy-peer-deps && npm run build` ✅
- May need more memory (upgrade from free tier)

#### Issue 2: Build Times Out
**Error**: "Build exceeded maximum time"
**Solution**:
- Free tier has build time limits
- May need to optimize build or upgrade

#### Issue 3: Environment Variable Not Set
**Error**: "NEXT_PUBLIC_API_URL is undefined"
**Solution**:
- Set `NEXT_PUBLIC_API_URL` in Render dashboard
- Must be set before build (it's baked in at build time)

#### Issue 4: Next.js Build Error
**Error**: TypeScript errors or missing files
**Solution**:
- Check all required files exist
- Verify TypeScript config is correct

## How to Get Error Logs from Render

1. Go to Render dashboard
2. Click on the failed service
3. Click "Logs" tab
4. Check build logs for specific errors
5. Look for error messages in red

## Quick Fixes

### Fix 1: Update Dockerfile for Render

Make sure Dockerfile uses correct port binding:

```dockerfile
# Use PORT from environment (Render provides this)
CMD ["python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "${PORT:-8000}"]
```

### Fix 2: Simplify Frontend Build

If build fails, try simpler build command:

```yaml
buildCommand: npm ci --legacy-peer-deps && npm run build
```

### Fix 3: Remove dockerContext (If Not Supported)

Some Render versions don't support `dockerContext`. Try removing it:

```yaml
dockerfilePath: ./backend/Dockerfile
# Remove dockerContext line
```

### Fix 4: Use Different Region

If Oregon region has issues, try another region:

```yaml
region: frankfurt  # or: singapore, mumbai
```

## Debugging Steps

1. **Check Build Logs**:
   - Render dashboard → Service → Logs
   - Look for error messages
   - Check which step failed

2. **Test Locally**:
   - Build Docker image locally
   - Run `npm run build` for frontend
   - Verify everything works

3. **Check File Paths**:
   - Verify all paths are relative to repo root
   - Check files exist in expected locations

4. **Check Environment Variables**:
   - Verify all required env vars are set
   - Check values are correct (no typos)

5. **Check Resource Limits**:
   - Free tier has limits
   - May need more memory/CPU
   - Check build logs for "out of memory" errors

## Most Common Issues

### 1. Missing Secrets
**Fix**: Add all required environment variables in Render dashboard

### 2. Build Timeout (Free Tier)
**Fix**: Optimize build or upgrade to Starter plan

### 3. Memory Issues (Free Tier - 512MB)
**Fix**: Optimize Docker image or upgrade to Starter plan

### 4. Port Configuration
**Fix**: Already configured ✅ - uses PORT env var

### 5. Dockerfile Path
**Fix**: Verify `dockerfilePath: ./backend/Dockerfile` is correct

## Next Steps After Getting Error Logs

1. Copy the exact error message from Render logs
2. Search for the error in this guide
3. Apply the fix
4. Commit and push changes
5. Render will automatically redeploy

## Getting Help

If you're stuck:
1. Check Render logs for specific error
2. Copy error message
3. Search Render documentation: https://render.com/docs
4. Check Render community: https://community.render.com

---

**What error message do you see in Render logs?** Share it and I can help fix it specifically!

