# Render Environment Variables - Complete Reference

Quick reference for all environment variables needed for Render deployment.

## Backend Environment Variables

### Required Variables

| Variable | Value | How to Get |
|----------|-------|------------|
| `AWS_REGION` | `us-east-2` | Your AWS region |
| `AWS_ACCESS_KEY_ID` | `AKIA...` | AWS IAM → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | `...` | AWS IAM → Users → Security credentials |
| `ATHENA_DATABASE` | `health_data_lake` | Your Athena database name |
| `ATHENA_WORKGROUP` | `health-data-tenant-queries` | Your Athena workgroup name |
| `S3_BUCKET` | `health-data-lake-640768199126-us-east-2` | Your S3 bucket name |
| `OPENAI_API_KEY` | `sk-...` | OpenAI dashboard → API keys |
| `JWT_SECRET` | `random-32-hex` | Generate: `openssl rand -hex 32` |
| `CORS_ORIGINS` | `https://frontend-url.onrender.com` | Frontend Render URL (after deployment) |

### Optional Variables (with defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_PROVIDER` | `openai` | LLM provider: `openai` or `ollama` |
| `OPENAI_MODEL` | `gpt-4` | OpenAI model to use |
| `JWT_ALGORITHM` | `HS256` | JWT signing algorithm |
| `JWT_EXPIRATION_HOURS` | `24` | JWT token expiration in hours |
| `HOST` | `0.0.0.0` | Server host (don't change) |
| `PORT` | (Auto) | Port (provided by Render - don't set) |
| `DEBUG` | `false` | Debug mode (keep false in production) |
| `S3_RESULTS_BUCKET` | Same as `S3_BUCKET` | S3 bucket for Athena results |
| `S3_RESULTS_PREFIX` | `athena-results/` | S3 prefix for Athena results |

### Example Backend Environment Variables

Copy-paste ready (replace values):

```bash
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_BUCKET=health-data-lake-640768199126-us-east-2
S3_RESULTS_PREFIX=athena-results/
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_MODEL=gpt-4
JWT_SECRET=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
HOST=0.0.0.0
DEBUG=false
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com
```

---

## Frontend Environment Variables

### Required Variables

| Variable | Value | How to Get |
|----------|-------|------------|
| `NEXT_PUBLIC_API_URL` | `https://backend-url.onrender.com` | Backend Render URL (with `https://`) |
| `NODE_ENV` | `production` | Always `production` for production builds |

### Example Frontend Environment Variables

Copy-paste ready (replace with your backend URL):

```bash
NEXT_PUBLIC_API_URL=https://health-intelligence-backend.onrender.com
NODE_ENV=production
```

**Important**: 
- `NEXT_PUBLIC_API_URL` must start with `https://` (not `http://`)
- No trailing slash in URL
- This variable is used at build time - rebuild frontend if you change it

---

## Security Best Practices

### 1. Generate Secure JWT Secret

```bash
# On your local machine
openssl rand -hex 32

# Output example:
# a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

Copy the output and use it as `JWT_SECRET`.

### 2. Never Commit Secrets

- ❌ Don't add `.env` files to Git
- ❌ Don't hardcode secrets in code
- ✅ Use Render environment variables
- ✅ Use different secrets for dev/staging/prod

### 3. CORS Configuration

**Development** (local):
```bash
CORS_ORIGINS=http://localhost:3000
```

**Production** (Render):
```bash
# Single domain
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com

# Multiple domains (comma-separated, no spaces)
CORS_ORIGINS=https://health-intelligence-frontend.onrender.com,https://app.yourdomain.com
```

**Important**:
- Always use `https://` in production
- No trailing slashes
- No spaces between domains (if multiple)
- Exact match required (case-sensitive)

### 4. Environment-Specific Configuration

Create different services on Render for:
- **Staging**: Test deployments
- **Production**: Live application

Use different:
- Service names
- Environment variables
- Instance sizes

---

## Setting Environment Variables in Render

### Method 1: During Service Creation

1. When creating service, scroll to **"Environment Variables"**
2. Click **"Add Environment Variable"**
3. Add each variable one by one
4. Click **"Create Web Service"**

### Method 2: After Service Creation

1. Go to service in Render dashboard
2. Click **"Environment"** tab
3. Click **"Add Environment Variable"**
4. Enter key and value
5. Click **"Save Changes"**
6. Service will auto-restart

### Method 3: Using Render CLI (Advanced)

```bash
# Install Render CLI
npm install -g render-cli

# Login
render login

# Set environment variable
render env set KEY=value --service your-service-name
```

---

## Common Issues & Solutions

### Issue: Backend can't connect to AWS

**Solution**:
- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
- Check IAM user has permissions for Athena and S3
- Verify `AWS_REGION` matches your AWS resources

### Issue: CORS errors in browser

**Solution**:
- Verify `CORS_ORIGINS` includes exact frontend URL with `https://`
- No trailing slash in URL
- Restart backend after changing `CORS_ORIGINS`
- Check browser console for exact error

### Issue: Frontend can't connect to backend

**Solution**:
- Verify `NEXT_PUBLIC_API_URL` is correct backend URL with `https://`
- Rebuild frontend after changing `NEXT_PUBLIC_API_URL` (it's baked at build time)
- Check backend is running and accessible: `curl https://backend-url/health`

### Issue: "Invalid token" errors

**Solution**:
- Verify `JWT_SECRET` is set correctly
- Use same `JWT_SECRET` across all backend instances (if scaling)
- Check `JWT_SECRET` is at least 32 characters
- Users may need to logout and login again after secret change

### Issue: Build fails

**Solution**:
- Check build logs for specific error
- Verify all required environment variables are set
- Check Node.js version (should be 18+)
- Verify Dockerfile paths are correct

---

## Quick Reference

### Minimal Required Variables

**Backend** (minimum to run):
```
AWS_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
ATHENA_DATABASE
ATHENA_WORKGROUP
S3_BUCKET
OPENAI_API_KEY
JWT_SECRET
CORS_ORIGINS
```

**Frontend** (minimum to run):
```
NEXT_PUBLIC_API_URL
```

### Recommended Production Variables

**Backend** (production-ready):
```
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=...
S3_RESULTS_BUCKET=...
S3_RESULTS_PREFIX=athena-results/
LLM_PROVIDER=openai
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-4
JWT_SECRET=... (32+ characters)
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
HOST=0.0.0.0
PORT= (don't set - Render provides)
DEBUG=false
CORS_ORIGINS=https://your-frontend-url.onrender.com
```

**Frontend** (production-ready):
```
NEXT_PUBLIC_API_URL=https://your-backend-url.onrender.com
NODE_ENV=production
```

---

For detailed deployment steps, see **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)**

