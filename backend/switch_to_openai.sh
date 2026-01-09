#!/bin/bash
# Switch backend to use OpenAI instead of Ollama

cd "$(dirname "$0")"

echo "🔧 Switching to OpenAI..."
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env <<EOF
# AWS Configuration
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=true
EOF
else
    # Update existing .env
    echo "Updating .env file..."
    
    # Remove old Ollama settings
    sed -i.bak '/^LLM_PROVIDER=/d' .env
    sed -i.bak '/^OLLAMA_BASE_URL=/d' .env
    sed -i.bak '/^OLLAMA_MODEL=/d' .env
    
    # Add OpenAI settings if not present
    if ! grep -q "^OPENAI_API_KEY=" .env; then
        echo "" >> .env
        echo "# LLM Configuration" >> .env
        echo "LLM_PROVIDER=openai" >> .env
        echo "OPENAI_API_KEY=your-openai-api-key-here" >> .env
        echo "OPENAI_MODEL=gpt-4" >> .env
    else
        # Update existing
        sed -i.bak 's/^LLM_PROVIDER=.*/LLM_PROVIDER=openai/' .env
    fi
    
    rm -f .env.bak
fi

echo "✅ Updated .env to use OpenAI"
echo ""
echo "⚠️  IMPORTANT: Edit .env and set your OPENAI_API_KEY"
echo "   You can get your API key from: https://platform.openai.com/api-keys"
echo ""
echo "After setting your API key, restart the backend:"
echo "   ./restart.sh"


