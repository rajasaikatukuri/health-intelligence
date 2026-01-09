#!/bin/bash
# Quick deployment script for production server

set -e

echo "=========================================="
echo "🚀 Health Intelligence Platform - Deployment"
echo "=========================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Running as root. Creating non-root user recommended."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get deployment method
echo "Select deployment method:"
echo "1. Docker Compose (Recommended)"
echo "2. Systemd + PM2 (Manual)"
echo "3. Docker Compose with Nginx"
read -p "Choose (1-3) [default: 1]: " method
method=${method:-1}

case $method in
    1)
        echo ""
        echo "🐳 Deploying with Docker Compose..."
        
        # Check if docker-compose is installed
        if ! command -v docker-compose &> /dev/null; then
            echo "Installing Docker Compose..."
            sudo apt update
            sudo apt install -y docker.io docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo "⚠️  Please log out and back in for Docker group to take effect"
        fi
        
        # Create .env file if not exists
        if [ ! -f ".env" ]; then
            echo "Creating .env file..."
            cat > .env <<EOF
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2
LLM_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4
JWT_SECRET=$(openssl rand -hex 32)
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
            echo "✅ Created .env file. Please update OPENAI_API_KEY and JWT_SECRET!"
        fi
        
        # Start services
        docker-compose up -d --build
        
        echo ""
        echo "✅ Deployment complete!"
        echo ""
        echo "Services are running:"
        echo "  Backend:  http://localhost:8000"
        echo "  Frontend: http://localhost:3000"
        echo ""
        echo "To view logs:"
        echo "  docker-compose logs -f"
        echo ""
        echo "To stop:"
        echo "  docker-compose down"
        ;;
        
    2)
        echo ""
        echo "📦 Deploying with Systemd + PM2..."
        echo ""
        echo "See DEPLOY.md for detailed instructions"
        echo ""
        echo "Quick steps:"
        echo "1. Setup backend systemd service"
        echo "2. Install PM2: npm install -g pm2"
        echo "3. Start frontend: pm2 start npm --name health-frontend -- start"
        echo "4. Configure Nginx"
        ;;
        
    3)
        echo ""
        echo "🐳 Deploying with Docker Compose + Nginx..."
        
        # Create nginx config directory
        mkdir -p nginx/conf.d nginx/ssl
        
        # Create nginx config
        cat > nginx/conf.d/health.conf <<'EOF'
upstream backend {
    server backend:8000;
}

upstream frontend {
    server frontend:3000;
}

server {
    listen 80;
    server_name _;

    # Backend API
    location /api {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Frontend
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

        # Start with docker-compose
        docker-compose up -d --build
        
        echo ""
        echo "✅ Deployment complete with Nginx!"
        echo ""
        echo "Access at: http://localhost"
        echo ""
        ;;
        
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Update .env file with production values"
echo "2. Configure domain name (if using)"
echo "3. Setup SSL certificate (Let's Encrypt)"
echo "4. Configure firewall"
echo "5. Setup monitoring"
echo ""
echo "See DEPLOY.md for detailed instructions"
echo ""

