# Render Free Tier Configuration

## Free Tier Limitations

Render's free tier has some limitations but is perfect for getting started:

### Free Tier Features ✅
- ✅ **512MB RAM** per service
- ✅ **0.1 CPU** per service
- ✅ **Automatic HTTPS** (SSL certificates)
- ✅ **Custom domains** (with SSL)
- ✅ **Auto-deploy from Git**
- ✅ **Logs and metrics**
- ✅ **Community support**

### Free Tier Limitations ⚠️
- ⚠️ **Spins down after 15 minutes of inactivity** (takes ~30s to wake up)
- ⚠️ **Limited CPU/RAM** (may be slower than paid plans)
- ⚠️ **100GB bandwidth/month** (usually plenty for testing)
- ⚠️ **No persistent disk** (filesystem is ephemeral)

## Updated render.yaml for Free Tier

The `render.yaml` is now configured with `plan: free` for both services.

## Important Notes for Free Tier

### 1. Cold Start Delay
- Services spin down after 15 minutes of inactivity
- First request after spin-down takes ~30 seconds
- Subsequent requests are fast

**Solution**: Consider using a free uptime monitor like UptimeRobot (checks every 5 minutes to keep services awake)

### 2. Resource Limitations
- 512MB RAM may be tight for some operations
- If you get "Out of Memory" errors, consider:
  - Optimizing your Docker images
  - Reducing concurrent requests
  - Using paid Starter plan ($7/month per service)

### 3. Storage
- Filesystem is ephemeral (resets on deploy)
- Store files in S3 (you're already doing this!)
- Don't store files in `/tmp` or local filesystem

## Alternative: Use Free Tier for Testing, Upgrade Later

You can:
1. Start with free tier to test deployment
2. Upgrade to Starter plan ($7/month) when you need:
   - Always-on (no spin-down)
   - More RAM/CPU
   - Better performance

## Free Tier is Perfect For

✅ Development and testing
✅ Personal projects
✅ Low-traffic applications
✅ Proof of concept
✅ Learning and experimentation

## When to Upgrade

Consider upgrading if:
- You need always-on (no spin-down delays)
- You're getting out-of-memory errors
- You need better performance
- You have production traffic

## Cost Comparison

| Plan | Cost | RAM | CPU | Always On | Notes |
|------|------|-----|-----|-----------|-------|
| **Free** | $0 | 512MB | 0.1 | ❌ | Spins down after 15min |
| **Starter** | $7/month | 1GB | 0.5 | ✅ | Good for production |
| **Standard** | $25/month | 2GB | 1.0 | ✅ | High performance |

## Your Current Configuration

Both services are set to `plan: free`:
- Backend: Free tier (512MB RAM)
- Frontend: Free tier (512MB RAM)

**Total Cost: $0/month** ✅

## Free Tier Best Practices

1. **Monitor usage**: Check Render dashboard for resource usage
2. **Optimize builds**: Reduce Docker image size
3. **Use caching**: Cache expensive operations
4. **Set up uptime monitoring**: Keep services awake (optional)

## After Deployment

Your app will work perfectly on free tier! Just remember:
- First request after 15min inactivity will be slower (~30s)
- Services will wake up automatically
- All features work the same!

Enjoy your free deployment! 🎉

