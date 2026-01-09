# 🔧 Fix: JWT Token Verification Failed

## Problem
You're seeing: `Error: Invalid token: Signature verification failed.`

This happens when:
1. The backend restarted and the JWT secret changed
2. The token was created with a different secret
3. You need to log in again

## Solution

### Step 1: Logout and Login Again

1. Click the **"Logout"** button in the frontend
2. Login again with username: `rajasaikatukuri`
3. This will create a new token with the current backend secret

### Step 2: Verify Backend is Running

```bash
curl http://localhost:8000/health
```

Should return:
```json
{"status":"healthy","aws_region":"us-east-2",...}
```

### Step 3: Test Login Endpoint

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "rajasaikatukuri"}'
```

Should return a token:
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "tenant_id": "rajasaikatukuri",
  "username": "rajasaikatukuri"
}
```

## Why This Happens

When you restart the backend:
- The JWT secret is loaded from `config.py` (default: `"dev-secret-change-in-production"`)
- Old tokens created before restart may not match if the secret changed
- **Solution:** Always log in again after restarting the backend

## Permanent Fix (Optional)

To use a consistent secret across restarts, add to `.env`:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend
echo "JWT_SECRET=my-consistent-secret-key-12345" >> .env
```

Then restart the backend.




