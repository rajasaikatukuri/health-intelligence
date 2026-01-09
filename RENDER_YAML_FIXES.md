# Render.yaml Common Issues & Fixes

## Common Issues

### 1. Comments in YAML
Render Blueprint YAML may not support comments well. **Fixed**: Removed all comments.

### 2. Boolean Values
Boolean values should be strings. **Fixed**: Changed `false` to `"false"` and `24` to `"24"`.

### 3. Property Names
- ✅ `dockerfilePath` - Correct
- ✅ `dockerContext` - Correct
- ✅ `healthCheckPath` - Correct
- ✅ `rootDir` - Correct

### 4. Environment Variables Format
All env vars must be in `key: value` format. **Fixed**: All env vars properly formatted.

## Fixed render.yaml

The corrected `render.yaml` has:
- ✅ No comments (removed all)
- ✅ Proper YAML indentation
- ✅ String values for numbers/booleans where needed
- ✅ All required properties
- ✅ Valid property names

## Secrets to Set Manually

After services are created, add these in Render Dashboard:

**Backend Service** → Environment:
```bash
AWS_ACCESS_KEY_ID=your-actual-key
AWS_SECRET_ACCESS_KEY=your-actual-secret
OPENAI_API_KEY=your-actual-key
JWT_SECRET=generate-with-openssl-rand-hex-32
```

**Frontend Service** → Environment:
- `NEXT_PUBLIC_API_URL` - Update with actual backend URL after deployment

## After Deployment

1. Get actual URLs from Render dashboard
2. Update backend `CORS_ORIGINS` with actual frontend URL
3. Update frontend `NEXT_PUBLIC_API_URL` with actual backend URL
4. Services will restart automatically

