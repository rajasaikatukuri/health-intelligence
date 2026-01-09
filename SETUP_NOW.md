# 🚀 Setup Now - Step by Step

Follow these steps to get your Health Intelligence Platform running.

---

## Step 1: Set Up Athena Tables (2 minutes)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/athena
chmod +x setup_tables.sh
./setup_tables.sh
```

**What this does:**
- Creates raw table (if needed)
- Creates silver view
- Creates 3 gold tables (daily_by_type, daily_features, weekly_features)

**Wait for:** "✅ All tables created successfully!"

---

## Step 2: Install & Start Ollama (2 minutes)

### Install Ollama

```bash
# On Mac
brew install ollama

# Or download from https://ollama.ai
```

### Start Ollama

```bash
# Terminal 1 - Start Ollama server
ollama serve
```

### Pull Model (in new terminal)

```bash
# Terminal 2 - Pull Llama 3 model
ollama pull llama3

# Verify
ollama list
```

**You should see:** `llama3` in the list

---

## Step 3: Start Backend (2 minutes)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Make start script executable
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

## Step 4: Start Frontend (2 minutes)

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend

# Install dependencies
npm install

# Start dev server
npm run dev
```

**Wait for:** "Local: http://localhost:3000"

---

## Step 5: Test the System (1 minute)

1. **Open browser:** http://localhost:3000

2. **Login:**
   - Username: `rajasaikatukuri` (or your tenant_id)
   - Click "Login"

3. **Test query:**
   - Type: "Summarize my last 30 days"
   - Press Enter
   - Wait for response with charts!

---

## 🎯 What You Need Running

You need **3 terminals** running:

**Terminal 1:** Ollama
```bash
ollama serve
```

**Terminal 2:** Backend
```bash
cd health-intelligence/backend
./start.sh
```

**Terminal 3:** Frontend
```bash
cd health-intelligence/frontend
npm run dev
```

---

## ✅ Success Checklist

- [ ] Athena tables created
- [ ] Ollama running and model pulled
- [ ] Backend running on port 8000
- [ ] Frontend running on port 3000
- [ ] Can login to frontend
- [ ] Can send chat messages
- [ ] Charts render in responses

---

## 🐛 Troubleshooting

### Backend won't start
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
python3 main.py
```

### Frontend won't start
```bash
cd frontend
rm -rf node_modules
npm install
npm run dev
```

### Ollama not working
```bash
# Check if running
curl http://localhost:11434/api/tags

# Restart
ollama serve
```

### No data in charts
- Check S3 has data for your tenant_id
- Verify Athena tables were created
- Check backend logs for errors

---

## 📚 Next Steps

1. Try example questions from the chat UI
2. Check backend logs to see agent flow
3. Explore the code structure
4. Read FUTURE_WORK.md for enhancements

---

**Ready to start? Run Step 1 now!** 🚀





