# Quick Start: Backend Server

## Start the Backend

Open a **new terminal** and run:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend
./start.sh
```

**OR manually:**

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Activate venv (if exists)
source venv/bin/activate

# If venv doesn't exist, create it:
# python3 -m venv venv
# source venv/bin/activate
# pip install -r requirements.txt

# Start server
python3 main.py
```

## Expected Output

You should see:
```
🚀 Starting Health Intelligence Platform Backend
================================================
Starting server...
Backend will be available at: http://localhost:8000
API docs at: http://localhost:8000/docs

INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## Verify Backend is Running

In another terminal, test:
```bash
curl http://localhost:8000/health
```

Should return: `{"status":"healthy"}`

## Test Login Endpoint

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "rajasaikatukuri"}'
```

Should return a JWT token.

---

## Troubleshooting

### Port 8000 already in use
```bash
# Find what's using port 8000
lsof -i :8000

# Kill it or change PORT in .env
```

### Module not found errors
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

### Ollama not running (optional)
The backend will work without Ollama, but chat features need it:
```bash
ollama serve
```





