#!/bin/bash
# Quick deployment script - easiest way to deploy

set -e

echo "=========================================="
echo "🚀 Quick Deploy - Health Intelligence Platform"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and back in."
    exit 0
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
fi

echo "✅ Prerequisites OK"
echo ""

# Create .env if not exists
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

# JWT Configuration (CHANGE IN PRODUCTION!)
JWT_SECRET=$(openssl rand -hex 32)

# Frontend Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000

# Server Configuration
DEBUG=false
EOF
    echo "✅ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: Update OPENAI_API_KEY in .env before deploying!"
    echo ""
    read -p "Press Enter to continue after updating .env (or Ctrl+C to cancel)..."
fi

# Build and start
echo ""
echo "Building and starting services..."
echo ""

docker-compose up -d --build

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📍 Services are running:"
echo "   Backend:  http://localhost:8000"
echo "   Frontend: http://localhost:3000"
echo "   API Docs: http://localhost:8000/docs"
echo ""
echo "📋 Useful commands:"
echo "   docker-compose logs -f        # View logs"
echo "   docker-compose ps             # Check status"
echo "   docker-compose restart        # Restart all"
echo "   docker-compose down           # Stop all"
echo ""
echo "🔧 Next steps:"
echo "   1. Configure domain name (update NEXT_PUBLIC_API_URL)"
echo "   2. Setup SSL with Let's Encrypt"
echo "   3. Configure firewall"
echo "   4. Setup monitoring"
echo ""
echo "See DEPLOY.md for detailed instructions"
echo ""

