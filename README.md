# Health Intelligence Platform

A production-ready, chat-based analytics platform for health data with natural language querying, interactive dashboards, and AI-powered insights.

## 🚀 Features

- **Natural Language Queries**: Ask questions about your health data in plain English
- **Interactive Dashboards**: Beautiful, interactive visualizations using Vega-Lite
- **Multi-Agent AI System**: Intelligent routing, SQL generation, and data analysis
- **iOS HealthKit Sync**: Native iOS app to sync Apple Health data to AWS
- **Tenant-Safe**: Built-in row-level security with tenant isolation
- **Athena Integration**: Query data directly from S3 using AWS Athena
- **Modern Stack**: FastAPI + LangGraph backend, Next.js frontend, SwiftUI iOS app

## 📋 Prerequisites

- **AWS Account** with:
  - S3 bucket with health data (Parquet format)
  - Athena database and workgroup configured
  - IAM user with Athena and S3 permissions
- **Python 3.10+** (for backend)
- **Node.js 18+** (for frontend)
- **Xcode 14+** (for iOS app - macOS only)
- **OpenAI API Key** (or use Ollama for local LLM)

## 🏗️ Architecture

```
┌─────────────┐         ┌──────────────┐         ┌──────────┐
│   Frontend  │ ──────> │   Backend    │ ──────> │  Athena  │
│  (Next.js)  │         │  (FastAPI)   │         │   (S3)   │
└─────────────┘         └──────────────┘         └──────────┘
                              │
                              ▼
                        ┌──────────┐
                        │   LLM    │
                        │ (OpenAI) │
                        └──────────┘
```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/health-intelligence.git
cd health-intelligence
```

### 4. iOS App Setup (Optional)

For syncing Apple HealthKit data:

1. **Open Xcode**
2. **Create new project** (SwiftUI App)
3. **Add HealthKit capability**
4. **Copy Swift files** from `ios-app/` directory
5. **Configure API endpoints** in `HealthSyncManager.swift`
6. **Run on real iPhone** (HealthKit doesn't work on simulator)

**Complete guide**: See **[ios-app/IOS_SETUP.md](./ios-app/IOS_SETUP.md)**

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env <<EOF
# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=your-s3-bucket-name
S3_RESULTS_BUCKET=your-s3-bucket-name
S3_RESULTS_PREFIX=athena-results/

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4

# JWT Configuration
JWT_SECRET=$(openssl rand -hex 32)
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=false

# CORS Configuration
CORS_ORIGINS=http://localhost:3000
EOF

# Start backend
python3 main.py
```

Backend will run at: http://localhost:8000

### 3. Frontend Setup

Open a new terminal:

```bash
cd frontend

# Install dependencies
npm install --legacy-peer-deps

# Create .env.local file
cat > .env.local <<EOF
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF

# Start frontend
npm run dev
```

Frontend will run at: http://localhost:3000

### 4. Access the Application

1. Open browser: http://localhost:3000
2. Login with username (this becomes your `tenant_id`)
3. Start asking questions about your health data!

## 📚 Documentation

- **[RUNBOOK.md](./RUNBOOK.md)** - Complete setup and configuration guide
- **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** - Deploy to Render.com (cloud hosting)
- **[GITHUB_SETUP.md](./GITHUB_SETUP.md)** - GitHub setup instructions
- **[RENDER_ENV_VARS.md](./RENDER_ENV_VARS.md)** - Environment variables reference
- **[ios-app/IOS_SETUP.md](./ios-app/IOS_SETUP.md)** - Complete iOS app setup guide

## 🔧 Configuration

### AWS Setup

1. Create S3 bucket for health data
2. Create Athena database and workgroup
3. Set up IAM user with permissions:
   - `AmazonAthenaFullAccess`
   - `AmazonS3ReadOnlyAccess`
   - Access to your specific bucket

### Athena Tables

The platform expects these tables in Athena:

- `health_data_raw` - External table pointing to S3 raw data
- `silver_health` - Standardized view/table
- `gold_daily_features` - Daily aggregated features
- `gold_weekly_features` - Weekly aggregated features
- `gold_daily_by_type` - Daily aggregations by data type

See `athena/` directory for DDL scripts.

### LLM Configuration

**Option 1: OpenAI (Recommended for production)**
```bash
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-4
```

**Option 2: Ollama (Free, local)**
```bash
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
```

Then start Ollama:
```bash
ollama serve
ollama pull llama3
```

## 📖 Usage Examples

### Example Queries

- "Summarize my last 30 days"
- "Compare last 7 days vs previous 7 days"
- "Show me my daily steps for this month"
- "Create a dashboard for cardio fitness"
- "What are the trends in my heart rate?"

### API Endpoints

- `POST /api/auth/login` - Login (username = tenant_id for dev)
- `POST /api/chat` - Send chat message
- `GET /api/me` - Get current user info
- `GET /health` - Health check
- `GET /docs` - API documentation (Swagger UI)

## 🏭 Production Deployment

### Deploy to Render.com (Recommended)

See **[RENDER_DEPLOY.md](./RENDER_DEPLOY.md)** for complete guide.

Quick steps:
1. Push code to GitHub
2. Go to https://dashboard.render.com
3. Create Blueprint from repository
4. Set environment variables
5. Deploy!

### Deploy to Other Platforms

The application includes:
- `Dockerfile` for backend (containerized deployment)
- `Dockerfile` for frontend (containerized deployment)
- `docker-compose.yml` for local Docker deployment
- `render.yaml` for Render Blueprint deployment

## 🔒 Security

### Production Checklist

- [ ] Change `JWT_SECRET` to secure random value (`openssl rand -hex 32`)
- [ ] Set `DEBUG=false` in production
- [ ] Configure `CORS_ORIGINS` with specific domains (not `*`)
- [ ] Use environment variables for all secrets
- [ ] Enable HTTPS (automatic on Render)
- [ ] Set up proper IAM roles (not access keys if possible)
- [ ] Enable query result caching to reduce Athena costs

## 📁 Project Structure

```
health-intelligence/
├── backend/              # FastAPI backend
│   ├── agents/          # LangGraph agents (router, data, dashboard, coach)
│   ├── athena_client.py # Athena query client
│   ├── auth.py          # JWT authentication
│   ├── config.py        # Configuration
│   ├── graph.py         # LangGraph workflow
│   ├── main.py          # FastAPI application
│   └── requirements.txt # Python dependencies
├── frontend/            # Next.js frontend
│   ├── app/            # Next.js app directory
│   ├── components/     # React components
│   └── package.json    # Node.js dependencies
├── ios-app/            # iOS app (Xcode + HealthKit)
│   ├── health_dataApp.swift      # Main app entry
│   ├── HealthDataService.swift   # HealthKit service
│   ├── HealthSyncManager.swift   # Sync manager
│   ├── HealthSyncView.swift      # SwiftUI view
│   ├── LocalNetworkPermission.swift # Network helper
│   └── IOS_SETUP.md     # Complete iOS setup guide
├── athena/             # Athena DDL scripts
│   ├── setup_tables.sh # Create tables
│   └── ...
├── render.yaml         # Render Blueprint config
├── docker-compose.yml  # Docker Compose config
└── README.md          # This file
```

## 🐛 Troubleshooting

### Backend Issues

**Error: "Cannot connect to Ollama"**
- Start Ollama: `ollama serve`
- Or switch to OpenAI in `.env`

**Error: "AWS credentials not found"**
- Check `.env` file has `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- Verify credentials are correct

**Error: "Athena table not found"**
- Run Athena setup scripts in `athena/` directory
- Verify table names match in `.env`

### Frontend Issues

**Error: "Cannot connect to backend"**
- Check backend is running at http://localhost:8000
- Verify `NEXT_PUBLIC_API_URL` in `.env.local` is correct

**Error: "Module not found: vega"**
- Run: `npm install --legacy-peer-deps`
- Check `package.json` dependencies

### Deployment Issues

**Error: "Build failed"**
- Check Render logs for specific error
- Verify all environment variables are set
- See [RENDER_TROUBLESHOOTING.md](./RENDER_TROUBLESHOOTING.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is open source and available for personal and commercial use.

## 🙏 Acknowledgments

- Built with [FastAPI](https://fastapi.tiangolo.com/)
- AI powered by [LangChain](https://langchain.com/) and [LangGraph](https://langchain.com/langgraph)
- Frontend built with [Next.js](https://nextjs.org/)
- Visualizations with [Vega-Lite](https://vega.github.io/vega-lite/)

## 📞 Support

For issues and questions:
- Check [RUNBOOK.md](./RUNBOOK.md) for setup guide
- Check [RENDER_TROUBLESHOOTING.md](./RENDER_TROUBLESHOOTING.md) for deployment issues
- Review existing documentation files

## 🎯 Next Steps

1. ✅ Clone repository
2. ✅ Configure AWS credentials
3. ✅ Set up Athena tables
4. ✅ Configure environment variables
5. ✅ Start backend and frontend
6. ✅ Start using the platform!

---

**Happy querying! 🎉**
