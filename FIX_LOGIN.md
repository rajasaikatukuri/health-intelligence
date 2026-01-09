# Fix Login Issue

## Problem
Cannot login - backend is not running.

## Solution

### Step 1: Start the Backend

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend
./start.sh
```

Or use the combined script:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
./START_ALL.sh
```

### Step 2: Verify Backend is Running

In a new terminal, test:

```bash
curl http://localhost:8000/health
```

Should return: `{"status":"ok",...}`

### Step 3: Test Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "rajasaikatukuri"}'
```

Should return a token.

### Step 4: Check Frontend

1. Make sure frontend is running: http://localhost:3000
2. Open browser console (F12)
3. Try to login
4. Check for errors in console

## Common Issues

### Issue 1: Backend not starting
- Check if port 8000 is in use: `lsof -ti:8000`
- Kill existing process: `kill $(lsof -ti:8000)`
- Check Python venv is activated
- Check .env file exists

### Issue 2: CORS errors
- Backend should have CORS enabled (already configured)
- Check backend logs for CORS errors

### Issue 3: Connection refused
- Backend not running
- Wrong URL (should be http://localhost:8000)
- Firewall blocking

### Issue 4: 401 Unauthorized
- Token expired (logout and login again)
- Invalid token format
- JWT secret mismatch

## Quick Test Script

Run this to test everything:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
./test_login.sh
```

This will:
1. Check if backend is running
2. Test login endpoint
3. Test /api/me endpoint
4. Show any errors

## After Fixing

Once backend is running:
1. Go to http://localhost:3000
2. Enter username: `rajasaikatukuri`
3. Click Login
4. Should redirect to chat page

