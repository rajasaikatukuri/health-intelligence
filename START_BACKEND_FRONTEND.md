# Start Backend and Frontend

Ollama is running! Now let's start the backend and frontend.

---

## Step 1: Pull Llama3 Model (if not done)

In a **new terminal** (keep Ollama running in Terminal 1):

```bash
ollama pull llama3
```

**This downloads ~4.7GB, takes a few minutes.**

**Verify:**
```bash
ollama list
# Should show: llama3
```

---

## Step 2: Start Backend (Terminal 2)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Make script executable
chmod +x start.sh

# Start backend
./start.sh
```

**Or manually:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 main.py
```

**Wait for:** 
```
Backend will be available at: http://localhost:8000
API docs at: http://localhost:8000/docs
```

**Test:**
```bash
curl http://localhost:8000/health
# Should return: {"status":"healthy"}
```

---

## Step 3: Start Frontend (Terminal 3)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend

# Install dependencies (first time only)
npm install

# Start dev server
npm run dev
```

**Wait for:**
```
- ready started server on 0.0.0.0:3000
- Local: http://localhost:3000
```

---

## Step 4: Test the System

1. **Open browser:** http://localhost:3000

2. **Login:**
   - Username: `rajasaikatukuri`
   - Click "Login"

3. **Test query:**
   - Type: "Summarize my last 30 days"
   - Press Enter
   - Wait for response (may take 10-30 seconds first time)

---

## ✅ What Should Be Running

- **Terminal 1:** `ollama serve` (Ollama server)
- **Terminal 2:** Backend (`./start.sh` or `python3 main.py`)
- **Terminal 3:** Frontend (`npm run dev`)

---

## 🐛 Troubleshooting

### Backend won't start

**"Module not found"**
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

**"Ollama connection failed"**
- Check Ollama is running: `curl http://localhost:11434/api/tags`
- Should return JSON with models

### Frontend won't start

**"Cannot find module"**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**"Cannot connect to API"**
- Check backend is running: `curl http://localhost:8000/health`
- Check frontend `.env.local` has correct API URL

---

**Start with Step 2 (Backend) now!** 🚀





