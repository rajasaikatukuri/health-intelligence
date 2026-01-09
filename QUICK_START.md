# 🚀 Quick Start Guide - After Laptop Restart

## Prerequisites Check

Before starting, ensure you have:
- ✅ Python 3.10+ installed
- ✅ Node.js 18+ installed
- ✅ AWS CLI configured (for Athena queries)
- ✅ Ollama installed and running (optional, for local LLM)

---

## Option 1: Use the Scripts (Recommended)

### Start Backend (Terminal 1)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
chmod +x START_BACKEND.sh
./START_BACKEND.sh
```

This will:
- ✅ Create/activate Python venv
- ✅ Install all dependencies
- ✅ Create .env file if missing
- ✅ Start backend on http://localhost:8000

### Start Frontend (Terminal 2)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
chmod +x START_FRONTEND.sh
./START_FRONTEND.sh
```

This will:
- ✅ Install Node.js dependencies
- ✅ Check backend connection
- ✅ Start frontend on http://localhost:3000

---

## Option 2: Manual Commands

### Backend Setup

```bash
# Navigate to backend
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Create venv (if doesn't exist)
python3 -m venv venv

# Activate venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env if missing
if [ ! -f ".env" ]; then
cat > .env <<EOF
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
fi

# Start server
python3 main.py
```

### Frontend Setup

```bash
# Navigate to frontend
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend

# Install dependencies
npm install --legacy-peer-deps

# Start dev server
npm run dev
```

---

## Verify Everything Works

### 1. Check Backend Health

```bash
curl http://localhost:8000/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "aws_region": "us-east-2",
  "athena_database": "health_data_lake"
}
```

### 2. Check Frontend

Open browser: http://localhost:3000

You should see the login page.

### 3. Test Login

- Username: `rajasaikatukuri` (or any tenant_id)
- Password: (not required for dev login)

---

## Troubleshooting

### Backend Issues

**Port 8000 already in use:**
```bash
# Find and kill process
lsof -ti :8000 | xargs kill -9
```

**Missing dependencies:**
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

**Ollama not running:**
```bash
# Start Ollama
ollama serve

# In another terminal, pull model
ollama pull llama3
```

### Frontend Issues

**Port 3000 already in use:**
```bash
# Find and kill process
lsof -ti :3000 | xargs kill -9
```

**Module not found errors:**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

**Vega library issues:**
```bash
cd frontend
npm install vega@5.25.0 vega-lite@5.16.3 vega-embed@6.25.0 --legacy-peer-deps --save
```

---

## Quick Commands Reference

```bash
# Backend
cd health-intelligence/backend
source venv/bin/activate
python3 main.py

# Frontend
cd health-intelligence/frontend
npm run dev

# Check what's running
lsof -i :8000  # Backend
lsof -i :3000  # Frontend

# Stop processes
lsof -ti :8000 | xargs kill -9  # Backend
lsof -ti :3000 | xargs kill -9  # Frontend
```

---

## Next Steps

1. ✅ Backend running on http://localhost:8000
2. ✅ Frontend running on http://localhost:3000
3. ✅ Login with username: `rajasaikatukuri`
4. ✅ Start asking health questions!

Example questions:
- "Summarize my last 30 days"
- "Show steps trend"
- "What day had the best activity?"
