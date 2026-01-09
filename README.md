# Health Intelligence Platform

A production-grade, chat-based analytics and dashboard system for Apple HealthKit data.

**Built with:** FastAPI, LangGraph, Next.js, AWS Athena, Ollama/OpenAI, Vega-Lite

---

## 🚀 Quick Start

```bash
# 1. Set up Athena tables
cd athena && ./setup_tables.sh

# 2. Start Ollama (Terminal 1)
ollama serve && ollama pull llama3

# 3. Start backend (Terminal 2)
cd backend && ./start.sh

# 4. Start frontend (Terminal 3)
cd frontend && npm install && npm run dev
```

**Then:** Open http://localhost:3000 and login with your tenant_id

---

## 📚 Documentation

- **[QUICK_START.md](./QUICK_START.md)** - 5-minute setup guide
- **[RUNBOOK.md](./RUNBOOK.md)** - Complete setup instructions
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - Architecture overview
- **[RESUME_DESCRIPTION.md](./RESUME_DESCRIPTION.md)** - Resume bullets
- **[FUTURE_WORK.md](./FUTURE_WORK.md)** - Enhancement roadmap
- **[FILE_TREE.md](./FILE_TREE.md)** - File structure

---

## ✨ Features

- 🔐 **Multi-tenant security** - Automatic tenant_id isolation
- 💬 **Natural language queries** - "Summarize my last 30 days"
- 📊 **Interactive dashboards** - Auto-generated Vega-Lite charts
- 🤖 **Multi-agent AI** - Router, Data, Dashboard, Coach, Anomaly agents
- 🔍 **Anomaly detection** - Statistical detection with explanations
- 💾 **Query caching** - Redis/in-memory for performance
- 📝 **Context memory** - 10-turn conversation history
- ⚡ **Cost optimized** - Gold tables, partition pruning, caching

---

## 🏗️ Architecture

```
User Question
    ↓
Router Agent (intent classification)
    ↓
Data Agent (SQL generation → Athena execution)
    ↓
Dashboard Agent (Vega-Lite chart generation)
    ↓
Coach Agent (natural language answer)
    ↓
Response (answer + charts + SQL)
```

**Security:** Every SQL query automatically includes `WHERE tenant_id = :tenant_id`

---

## 🛠️ Tech Stack

- **Backend:** FastAPI, LangGraph, LangChain, boto3
- **Frontend:** Next.js 14, TypeScript, Tailwind CSS
- **Database:** AWS Athena (Presto SQL)
- **Storage:** AWS S3 (Parquet)
- **LLM:** Ollama (local) + OpenAI (optional)
- **Charts:** Vega-Lite (free, open-source)

---

## 📊 Example Queries

- "Summarize my last 30 days"
- "Show steps trend and explain spikes"
- "Compare last 7 days vs previous 7 days"
- "What day had the best activity?"
- "Create a dashboard for cardio fitness"
- "Am I improving this month?"
- "Detect anomalies in heart rate"

---

## 🔒 Security

- ✅ JWT authentication
- ✅ Tenant isolation (automatic SQL filtering)
- ✅ HTTPS enforcement
- ✅ No credentials in frontend
- ✅ SQL injection prevention

---

## 📁 Project Structure

```
health-intelligence/
├── backend/          # FastAPI + LangGraph (12 files)
│   ├── agents/       # Multi-agent system
│   ├── main.py       # FastAPI app
│   └── graph.py      # LangGraph workflow
├── frontend/         # Next.js app (8 files)
│   ├── app/          # Next.js pages
│   └── components/   # React components
├── athena/           # DDL/CTAS scripts
└── docs/             # Documentation
```

---

## 💰 Cost

- **Athena:** ~$5/TB scanned (optimized)
- **S3:** ~$0.023/GB storage
- **Ollama:** Free (local)
- **OpenAI:** ~$0.01-0.10/query (optional)

**Estimated:** $20-100/month (depending on usage)

---

## ✅ Status

**Production-ready:** All features implemented, tested, and documented.

---

## 📖 Next Steps

1. Read [QUICK_START.md](./QUICK_START.md) for setup
2. Follow [RUNBOOK.md](./RUNBOOK.md) for detailed instructions
3. Check [FUTURE_WORK.md](./FUTURE_WORK.md) for enhancements

---

**Built as a production-grade system with security, performance, and scalability in mind.** 🚀

