# Health Intelligence Platform - File Tree

Complete file structure of the project.

```
health-intelligence/
├── README.md                          # Project overview
├── RUNBOOK.md                         # Complete setup guide
├── RESUME_DESCRIPTION.md              # Resume bullet points
├── FUTURE_WORK.md                     # Enhancement roadmap
├── FILE_TREE.md                       # This file
│
├── athena/                            # Athena DDL/CTAS scripts
│   ├── setup_tables.sh                # Create all tables/views
│   └── refresh_gold_tables.sh         # Refresh gold tables
│
├── backend/                           # FastAPI + LangGraph backend
│   ├── requirements.txt               # Python dependencies
│   ├── config.py                     # Configuration (Pydantic)
│   ├── auth.py                       # JWT authentication
│   ├── athena_client.py              # Athena query client
│   ├── cache.py                      # Query result caching
│   ├── llm_client.py                 # LLM client (Ollama/OpenAI)
│   ├── graph.py                      # LangGraph state & workflow
│   ├── main.py                       # FastAPI application
│   ├── start.sh                      # Start script
│   │
│   └── agents/                       # LangGraph agents
│       ├── __init__.py               # Agent exports
│       ├── router_agent.py           # Intent classification
│       ├── data_agent.py             # SQL generation & execution
│       ├── dashboard_agent.py       # Vega-Lite chart generation
│       ├── coach_agent.py           # Health insights & explanations
│       └── anomaly_agent.py          # Anomaly detection
│
└── frontend/                          # Next.js frontend
    ├── package.json                  # Node dependencies
    ├── next.config.js              # Next.js config
    ├── tsconfig.json                 # TypeScript config
    ├── tailwind.config.js            # Tailwind CSS config
    ├── postcss.config.js             # PostCSS config
    │
    ├── app/                          # Next.js app directory
    │   ├── layout.tsx                # Root layout
    │   ├── page.tsx                  # Main page (routing)
    │   └── globals.css               # Global styles
    │
    └── components/                   # React components
        ├── LoginPage.tsx             # Login UI
        ├── ChatPage.tsx              # Chat interface
        └── ChartRenderer.tsx         # Vega-Lite renderer
```

## Key Files Explained

### Backend

- **`main.py`**: FastAPI app with `/api/chat`, `/api/auth/login`, `/api/me` endpoints
- **`graph.py`**: LangGraph workflow orchestrating agents
- **`agents/`**: Specialized agents for different tasks
- **`athena_client.py`**: Secure Athena query execution with tenant isolation
- **`cache.py`**: Query result caching (Redis or in-memory)

### Frontend

- **`app/page.tsx`**: Main routing logic (login vs chat)
- **`components/ChatPage.tsx`**: Chat UI with chart rendering
- **`components/ChartRenderer.tsx`**: Vega-Lite chart component

### Athena

- **`setup_tables.sh`**: Creates all tables/views
- **`refresh_gold_tables.sh`**: Refreshes materialized views

## File Count

- **Backend**: 12 Python files
- **Frontend**: 8 TypeScript/JS files
- **Athena**: 2 shell scripts
- **Docs**: 5 markdown files

**Total**: ~27 files





