# 🔧 Fix: Ollama Connection Error

## Problem
```
Error: HTTPConnectionPool(host='localhost', port=11434): Max retries exceeded
```

This means **Ollama is not running** on your machine.

---

## Solution 1: Start Ollama (Recommended for Free/Local)

### Quick Start:
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence
chmod +x START_OLLAMA.sh
./START_OLLAMA.sh
```

### Manual Start:
```bash
# Start Ollama server
ollama serve

# In another terminal, pull the model (first time only)
ollama pull llama3
```

### Verify Ollama is Running:
```bash
curl http://localhost:11434/api/tags
```

Should return a list of models.

---

## Solution 2: Use OpenAI Instead (If You Have API Key)

If you have an OpenAI API key, you can switch to OpenAI:

### Step 1: Update Backend `.env`
```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Edit .env file
cat >> .env <<EOF
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-api-key-here
OPENAI_MODEL=gpt-4
EOF
```

### Step 2: Restart Backend
```bash
# Stop current backend (Ctrl+C)
# Then restart
./START_BACKEND.sh
```

---

## Solution 3: Install Ollama (If Not Installed)

### macOS:
```bash
brew install ollama
```

### Or Download:
Visit: https://ollama.ai/download

### After Installation:
```bash
# Start Ollama
ollama serve

# Pull llama3 model (first time)
ollama pull llama3
```

---

## Verify Everything Works

### 1. Check Ollama:
```bash
curl http://localhost:11434/api/tags
```

### 2. Test Backend Health:
```bash
curl http://localhost:8000/health
```

### 3. Try Your Question Again:
Go back to the frontend and ask: **"Summarize my last 30 days"**

---

## Quick Commands

```bash
# Start Ollama
ollama serve

# Check if running
curl http://localhost:11434/api/tags

# Pull model (first time)
ollama pull llama3

# List models
ollama list

# Stop Ollama
pkill ollama
```

---

## Recommended Setup

**Terminal 1 - Ollama:**
```bash
ollama serve
```

**Terminal 2 - Backend:**
```bash
cd health-intelligence/backend
./START_BACKEND.sh
```

**Terminal 3 - Frontend:**
```bash
cd health-intelligence/frontend
npm run dev
```

---

After starting Ollama, refresh the frontend and try your question again!




