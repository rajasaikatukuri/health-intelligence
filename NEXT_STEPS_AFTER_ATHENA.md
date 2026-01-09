# ✅ Athena Tables Created! Next Steps

Your Athena tables are ready. Now let's start the backend and frontend.

---

## Step 1: Start Ollama (Terminal 1)

```bash
# Start Ollama server
ollama serve
```

**In a new terminal, pull the model:**
```bash
ollama pull llama3
```

**Verify:**
```bash
ollama list
# Should show: llama3
```

---

## Step 2: Start Backend (Terminal 2)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Make script executable (if needed)
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

**Wait for:** "Backend will be available at: http://localhost:8000"

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

**Wait for:** "Local: http://localhost:3000"

---

## Step 4: Test the System

1. **Open browser:** http://localhost:3000

2. **Login:**
   - Username: `rajasaikatukuri`
   - Click "Login"

3. **Test queries:**
   - "Summarize my last 30 days"
   - "Show steps trend"
   - "Compare last 7 days vs previous 7 days"

---

## ✅ What You Should See

- **Backend running** on port 8000
- **Frontend running** on port 3000
- **Ollama running** on port 11434
- **Chat interface** working
- **Charts rendering** in responses

---

## 🐛 Troubleshooting

### Backend Issues

**"Module not found"**
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

**"Ollama connection failed"**
- Check Ollama is running: `curl http://localhost:11434/api/tags`
- Restart: `ollama serve`

### Frontend Issues

**"Cannot connect to API"**
- Check backend is running on port 8000
- Check `NEXT_PUBLIC_API_URL` in `.env.local` (or use default)

**"Charts not rendering"**
- Check browser console for errors
- Verify Vega-Lite dependencies: `npm install`

---

## 🎯 You're Ready!

Once all 3 services are running:
- ✅ Athena tables: Created
- ✅ Ollama: Running
- ✅ Backend: Running
- ✅ Frontend: Running

**Start asking questions about your health data!** 🚀





