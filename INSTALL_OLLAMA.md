# Install Ollama

## Option 1: Install Ollama (Recommended for Free Local LLM)

### On Mac:

```bash
# Install via Homebrew
brew install ollama

# Or download from https://ollama.ai
```

### Verify Installation:

```bash
ollama --version
```

### Start Ollama:

```bash
ollama serve
```

### Pull Model (in new terminal):

```bash
ollama pull llama3
# This downloads ~4.7GB, takes a few minutes
```

### Verify Model:

```bash
ollama list
# Should show: llama3
```

---

## Option 2: Use OpenAI Instead (No Installation Needed)

If you don't want to install Ollama, you can use OpenAI instead.

### Step 1: Get OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy the key

### Step 2: Update Backend Config

Edit `backend/.env` or create it:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Create .env file
cat > .env <<EOF
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-4
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
```

Replace `sk-your-key-here` with your actual OpenAI API key.

### Step 3: Start Backend

```bash
./start.sh
```

**That's it!** No Ollama needed.

---

## Which Should You Use?

### Use Ollama If:
- ✅ You want free LLM (no API costs)
- ✅ You have 4-8GB RAM available
- ✅ You don't mind slower responses (3-10 seconds)
- ✅ You want to run completely offline

### Use OpenAI If:
- ✅ You want faster responses (1-3 seconds)
- ✅ You don't want to install anything
- ✅ You have API key and budget (~$0.01-0.10 per query)
- ✅ You want better quality responses

---

## Quick Start (OpenAI)

If you have an OpenAI API key, use this:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Create .env with OpenAI config
echo "LLM_PROVIDER=openai" > .env
echo "OPENAI_API_KEY=sk-your-key-here" >> .env
echo "OPENAI_MODEL=gpt-4" >> .env
echo "AWS_REGION=us-east-2" >> .env
echo "ATHENA_DATABASE=health_data_lake" >> .env
echo "ATHENA_WORKGROUP=health-data-tenant-queries" >> .env

# Start backend
./start.sh
```

**No Ollama needed!**

---

**Choose your option and continue!** 🚀





