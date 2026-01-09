# 🚀 Simple Start Guide

## Easiest Way: Run This Command

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
./START_BOTH.sh
```

This starts both backend and frontend in the background. Wait ~30 seconds, then open http://localhost:3000

---

## Or Start Them Separately (2 Terminal Windows)

### Terminal 1 - Backend:
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
./START_BACKEND.sh
```

### Terminal 2 - Frontend:
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
./START_FRONTEND.sh
```

---

## Manual Commands (Copy & Paste)

### Backend:
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 main.py
```

### Frontend (in a new terminal):
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend
npm install --legacy-peer-deps
npm run dev
```

---

## Verify It's Working

```bash
# Check backend
curl http://localhost:8000/health

# Should see:
# {"status":"healthy","aws_region":"us-east-2",...}
```

Then open browser: **http://localhost:3000**

---

## Stop Servers

If using `START_BOTH.sh`, press `Ctrl+C` in that terminal.

Or manually:
```bash
# Find and kill processes
lsof -ti :8000 | xargs kill -9  # Backend
lsof -ti :3000 | xargs kill -9  # Frontend
```




