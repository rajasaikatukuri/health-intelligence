# Deployment Guide - Health Intelligence Platform

Complete guide for deploying to a production server.

## Prerequisites

- Ubuntu/Debian server (or similar Linux)
- Python 3.10+
- Node.js 18+
- Nginx (for reverse proxy)
- Domain name (optional, for HTTPS)
- AWS credentials configured on server

## Quick Deployment

### Option 1: Using Docker (Recommended)

```bash
docker-compose up -d
```

See `docker-compose.yml` for configuration.

### Option 2: Manual Deployment

Follow the steps below.

## Step-by-Step Deployment

### Step 1: Prepare Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3-pip python3-venv nginx nodejs npm git

# Install Node.js 18+ if needed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Step 2: Clone Repository

```bash
cd /opt
sudo git clone <your-repo-url> health-intelligence
sudo chown -R $USER:$USER health-intelligence
cd health-intelligence
```

### Step 3: Backend Deployment

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create production .env
cat > .env <<EOF
# AWS Configuration
AWS_REGION=us-east-2
ATHENA_DATABASE=health_data_lake
ATHENA_WORKGROUP=health-data-tenant-queries
S3_BUCKET=health-data-lake-640768199126-us-east-2

# LLM Configuration
LLM_PROVIDER=openai
OPENAI_API_KEY=your-actual-openai-api-key
OPENAI_MODEL=gpt-4

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=false

# JWT Configuration (CHANGE IN PRODUCTION!)
JWT_SECRET=your-very-secure-random-secret-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
EOF

# Test backend
python3 main.py
```

### Step 4: Frontend Deployment

```bash
cd ../frontend

# Install dependencies
npm install --legacy-peer-deps --production=false

# Create production .env.local
cat > .env.local <<EOF
NEXT_PUBLIC_API_URL=http://your-server-ip:8000
# Or with domain:
# NEXT_PUBLIC_API_URL=https://api.yourdomain.com
EOF

# Build for production
npm run build

# Test production build
npm start
```

### Step 5: Setup Systemd Services

#### Backend Service

```bash
sudo nano /etc/systemd/system/health-backend.service
```

Add:
```ini
[Unit]
Description=Health Intelligence Platform Backend
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/health-intelligence/backend
Environment="PATH=/opt/health-intelligence/backend/venv/bin"
ExecStart=/opt/health-intelligence/backend/venv/bin/python3 main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable health-backend
sudo systemctl start health-backend
sudo systemctl status health-backend
```

#### Frontend Service (PM2 - Recommended)

```bash
# Install PM2
sudo npm install -g pm2

# Start frontend with PM2
cd /opt/health-intelligence/frontend
pm2 start npm --name "health-frontend" -- start
pm2 save
pm2 startup
```

### Step 6: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/health-intelligence
```

Add:
```nginx
# Backend API
server {
    listen 80;
    server_name api.yourdomain.com;  # Or your server IP

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
}

# Frontend
server {
    listen 80;
    server_name yourdomain.com;  # Or your server IP

    location / {
        proxy_pass http://localhost:3000;
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
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/health-intelligence /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 7: Setup SSL with Let's Encrypt (Optional but Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com -d api.yourdomain.com

# Auto-renewal
sudo certbot renew --dry-run
```

### Step 8: Firewall Configuration

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

## Production Checklist

- [ ] Change JWT_SECRET to a secure random value
- [ ] Set DEBUG=false in backend .env
- [ ] Configure proper CORS origins (not *)
- [ ] Setup SSL/HTTPS
- [ ] Configure AWS credentials securely (use IAM roles if on EC2)
- [ ] Setup log rotation
- [ ] Configure monitoring/alerting
- [ ] Setup backups
- [ ] Test all endpoints
- [ ] Load testing

## Useful Commands

```bash
# Backend logs
sudo journalctl -u health-backend -f

# Frontend logs
pm2 logs health-frontend

# Restart services
sudo systemctl restart health-backend
pm2 restart health-frontend
sudo systemctl restart nginx

# Check status
sudo systemctl status health-backend
pm2 status
sudo nginx -t
```

## Troubleshooting

### Backend not starting
```bash
# Check logs
sudo journalctl -u health-backend -n 50

# Check if port is in use
sudo lsof -i :8000

# Test manually
cd /opt/health-intelligence/backend
source venv/bin/activate
python3 main.py
```

### Frontend not building
```bash
# Clear cache
rm -rf .next node_modules
npm install --legacy-peer-deps
npm run build
```

### Nginx errors
```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Check access logs
sudo tail -f /var/log/nginx/access.log
```

## Security Recommendations

1. **JWT Secret**: Use a long random string (32+ characters)
2. **Environment Variables**: Never commit .env files
3. **CORS**: Restrict to specific domains in production
4. **Rate Limiting**: Add rate limiting to API endpoints
5. **HTTPS Only**: Force HTTPS in production
6. **AWS Credentials**: Use IAM roles instead of access keys when possible
7. **Firewall**: Only open necessary ports
8. **Updates**: Keep system and dependencies updated

## Monitoring

Consider setting up:
- **Application Monitoring**: Sentry, DataDog, or New Relic
- **Log Aggregation**: ELK Stack or CloudWatch
- **Uptime Monitoring**: UptimeRobot or Pingdom
- **Performance Monitoring**: APM tools

## Backup Strategy

- Database backups (if using database)
- S3 data backups (AWS S3 versioning)
- Configuration backups
- SSL certificate backups

## Scaling

For high traffic:
- Use multiple backend instances with load balancer
- Use CDN for frontend static assets
- Consider caching layer (Redis)
- Database connection pooling
- Query result caching

