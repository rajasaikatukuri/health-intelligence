# Start Frontend - Final Step!

Backend is running! Now let's start the frontend.

---

## Step 1: Start Frontend (Terminal 3)

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

## Step 2: Test the System

1. **Open browser:** http://localhost:3000

2. **Login:**
   - Username: `rajasaikatukuri`
   - Click "Login"

3. **Test queries:**
   - "Summarize my last 30 days"
   - "Show steps trend"
   - "Compare last 7 days vs previous 7 days"
   - "What day had the best activity?"
   - "Create a dashboard for cardio fitness"

---

## ✅ What Should Be Running

- ✅ **Terminal 1:** `ollama serve` (Ollama server)
- ✅ **Terminal 2:** Backend (`python3 main.py` or `./start.sh`)
- ⏳ **Terminal 3:** Frontend (`npm run dev`) ← **Do this now!**

---

## 🎯 Expected Behavior

1. **Login page** appears
2. **Enter username** → Click Login
3. **Chat interface** loads
4. **Type question** → Press Enter
5. **Wait 10-30 seconds** (first query takes longer)
6. **See response** with:
   - Natural language answer
   - Charts (if applicable)
   - SQL query (in "Show SQL" dropdown)

---

## 🐛 Troubleshooting

### Frontend won't start

**"Cannot find module"**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run dev
```

**"Port 3000 already in use"**
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different port
PORT=3001 npm run dev
```

### Can't connect to backend

**"Network error"**
- Check backend is running: `curl http://localhost:8000/health`
- Should return: `{"status":"healthy"}`

**"401 Unauthorized"**
- This is normal on first load
- Just login with your username

---

## 🎉 Success!

Once frontend is running:
- ✅ All 3 services running
- ✅ Chat interface accessible
- ✅ Ready to ask questions!

**Start the frontend now!** 🚀





