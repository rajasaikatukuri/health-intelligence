# Health Intelligence Platform - Runbook

Complete step-by-step guide to set up and run the Health Intelligence Platform.

---

## Prerequisites

- **Mac** (or Linux with similar setup)
- **Python 3.10+**
- **Node.js 18+**
- **AWS CLI** configured with credentials
- **AWS Account** with access to:
  - Athena
  - S3 (data lake bucket)
  - Parameter Store (for JWT secret)
- **Ollama** (for local LLM) OR OpenAI API key

---

## Step 1: Set Up Athena Tables

### 1.1 Navigate to Athena Directory

```bash
cd health-intelligence/athena
```

### 1.2 Run Setup Script

```bash
chmod +x setup_tables.sh
./setup_tables.sh
```

**What this does:**
- Creates `health_data_raw` external table (if not exists)
- Creates `silver_health` view
- Creates `gold_daily_by_type` table (CTAS)
- Creates `gold_daily_features` table (CTAS)
- Creates `gold_weekly_features` table (CTAS)

**Expected output:**
```
✅ All tables created successfully!
```

**Note:** Gold tables are created with 90-day lookback. To refresh data, run:
```bash
./refresh_gold_tables.sh
```

---

## Step 2: Set Up Ollama (Local LLM)

### 2.1 Install Ollama

```bash
# On Mac
brew install ollama

# Or download from https://ollama.ai
```

### 2.2 Start Ollama

```bash
ollama serve
```

### 2.3 Pull Model

```bash
# Pull Llama 3 (recommended)
ollama pull llama3

# Or pull Mistral
ollama pull mistral
```

**Verify:**
```bash
ollama list
# Should show llama3 or mistral
```

---

## Step 3: Set Up Backend

### 3.1 Navigate to Backend

```bash
cd health-intelligence/backend
```

### 3.2 Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3.3 Install Dependencies

```bash
pip install -r requirements.txt
```

### 3.4 Configure Environment

Create `.env` file:

```bash
cp .env.example .env
# Edit .env with your settings
```

**Minimum `.env` configuration:**
```env
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
```

**For OpenAI (optional):**
```env
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4
```

### 3.5 Start Backend

```bash
chmod +x start.sh
./start.sh
```

**Or manually:**
```bash
source venv/bin/activate
python3 main.py
```

**Expected output:**
```
🚀 Starting Health Intelligence Platform Backend
Backend will be available at: http://localhost:8000
API docs at: http://localhost:8000/docs
```

**Verify:**
```bash
curl http://localhost:8000/health
# Should return: {"status":"healthy"}
```

---

## Step 4: Set Up Frontend

### 4.1 Navigate to Frontend

```bash
cd health-intelligence/frontend
```

### 4.2 Install Dependencies

```bash
npm install
```

### 4.3 Configure Environment

Create `.env.local` (optional, defaults work for local dev):

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 4.4 Start Frontend

```bash
npm run dev
```

**Expected output:**
```
- ready started server on 0.0.0.0:3000
- Local: http://localhost:3000
```

---

## Step 5: Test the System

### 5.1 Open Frontend

Navigate to: http://localhost:3000

### 5.2 Login

- Enter username: `rajasaikatukuri` (or your tenant_id)
- Click "Login"
- You should see the chat interface

### 5.3 Test Queries

Try these example questions:

1. **"Summarize my last 30 days"**
   - Should return summary with statistics

2. **"Show steps trend"**
   - Should return chart + explanation

3. **"Compare last 7 days vs previous 7 days"**
   - Should return comparison

4. **"What day had the best activity?"**
   - Should return specific day

5. **"Create a dashboard for cardio fitness"**
   - Should return multiple charts

6. **"Detect anomalies in heart rate"**
   - Should detect and explain anomalies

### 5.4 Verify Charts

- Charts should render inline
- Click "Explain this chart" to get explanations
- SQL queries should be visible in "Show SQL" dropdown

---

## Step 6: Verify Data Flow

### 6.1 Check Backend Logs

Backend should show:
- Query execution
- LLM calls
- Chart generation

### 6.2 Check Athena Queries

In AWS Console:
- Go to Athena
- Check query history
- Verify queries include `tenant_id` filter

### 6.3 Check S3 Results

Athena query results are stored in:
```
s3://health-data-lake-640768199126-us-east-2/athena-results/
```

---

## Troubleshooting

### Backend Issues

**"Module not found"**
```bash
# Reinstall dependencies
pip install -r requirements.txt
```

**"AWS credentials not found"**
```bash
# Configure AWS CLI
aws configure
```

**"Ollama connection failed"**
```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# Restart Ollama
ollama serve
```

### Frontend Issues

**"Cannot connect to API"**
- Check backend is running on port 8000
- Check `NEXT_PUBLIC_API_URL` in `.env.local`

**"Charts not rendering"**
- Check browser console for errors
- Verify Vega-Lite dependencies installed: `npm install`

### Athena Issues

**"Table not found"**
- Run `setup_tables.sh` again
- Check table exists in Athena console

**"Query timeout"**
- Reduce `DEFAULT_LOOKBACK_DAYS` in backend config
- Check S3 data exists for date range

**"No data returned"**
- Verify data exists in S3 for your tenant_id
- Check date range in query
- Verify partition projection is working

---

## Production Deployment

### Backend

1. **Deploy to AWS:**
   - Use ECS/Fargate or Lambda
   - Set environment variables
   - Use RDS/ElastiCache for sessions/cache

2. **Security:**
   - Use HTTPS
   - Rotate JWT secret
   - Enable CORS for frontend domain only
   - Use IAM roles (not access keys)

### Frontend

1. **Deploy to Vercel/Netlify:**
   ```bash
   npm run build
   # Deploy build output
   ```

2. **Environment:**
   - Set `NEXT_PUBLIC_API_URL` to production backend URL
   - Enable HTTPS

---

## Quick Reference

### Start Everything

```bash
# Terminal 1: Ollama
ollama serve

# Terminal 2: Backend
cd health-intelligence/backend
./start.sh

# Terminal 3: Frontend
cd health-intelligence/frontend
npm run dev
```

### URLs

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Ollama: http://localhost:11434

### Test Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "rajasaikatukuri"}'

# Chat (with token from login)
curl -X POST http://localhost:8000/api/chat \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Summarize my last 30 days"}'
```

---

## Next Steps

1. ✅ System is running
2. ✅ Test with example questions
3. ✅ Verify charts render
4. ✅ Check anomaly detection
5. 📖 Read `FUTURE_WORK.md` for enhancements

---

**Your Health Intelligence Platform is ready!** 🚀





