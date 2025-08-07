#!/bin/bash

# EmotionAI EC2 Bootstrap Script
# This script sets up the FastAPI backend on EC2 instances

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    supervisor \
    awscli \
    jq \
    git \
    htop \
    curl \
    unzip

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create application directory
mkdir -p /opt/emotion-ai-api
cd /opt/emotion-ai-api

# Clone your repository (replace with your actual repo)
# For now, we'll create a placeholder structure
cat > requirements.txt << 'EOF'
fastapi[all]==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.7
alembic==1.12.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
redis==5.0.1
boto3==1.34.0
python-dotenv==1.0.0
openai==1.3.7
pydantic==2.5.1
EOF

# Install Python dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create a basic FastAPI app structure (placeholder)
cat > main.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="EmotionAI API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health/")
async def health_check():
    return {"status": "healthy", "message": "EmotionAI API is running"}

@app.get("/health/detailed")
async def detailed_health():
    # Add database connectivity check here
    return {
        "status": "healthy",
        "database": "connected",
        "redis": "connected",
        "version": "1.0.0"
    }

@app.get("/")
async def root():
    return {"message": "Welcome to EmotionAI API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Get secrets from AWS Secrets Manager (if available)
SECRETS_FILE="/opt/secrets.json"
if aws secretsmanager get-secret-value --secret-id emotion-ai/database --query SecretString --output text > $SECRETS_FILE 2>/dev/null; then
    logger "Successfully retrieved secrets from AWS Secrets Manager"
else
    # Create default secrets file for initial setup
    cat > $SECRETS_FILE << 'EOF'
{
  "database_url": "${database_url}",
  "redis_url": "redis://localhost:6379",
  "jwt_secret": "your-jwt-secret-here"
}
EOF
fi

# Create environment file
cat > .env << EOF
DATABASE_URL=$(jq -r .database_url $SECRETS_FILE)
REDIS_URL=$(jq -r .redis_url $SECRETS_FILE)
JWT_SECRET=$(jq -r .jwt_secret $SECRETS_FILE)
ENVIRONMENT=production
EOF

# Create systemd service
cat > /etc/systemd/system/emotion-ai.service << 'EOF'
[Unit]
Description=EmotionAI FastAPI Backend
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/emotion-ai-api
Environment=PATH=/opt/emotion-ai-api/venv/bin
EnvironmentFile=/opt/emotion-ai-api/.env
ExecStart=/opt/emotion-ai-api/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2 --access-log
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/emotion-ai-api

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chown -R ubuntu:ubuntu /opt/emotion-ai-api
chmod +x /opt/emotion-ai-api/main.py

# Configure Nginx as reverse proxy
cat > /etc/nginx/sites-available/emotion-ai << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health/ {
        proxy_pass http://127.0.0.1:8000/health/;
        access_log off;
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/emotion-ai /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/emotion-ai/nginx-access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/emotion-ai/nginx-error",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "EmotionAI/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_time_wait"],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": ["swap_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start services
systemctl daemon-reload
systemctl enable emotion-ai
systemctl start emotion-ai
systemctl enable nginx
systemctl start nginx
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Wait for services to start
sleep 10

# Test if the application is running
if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
    echo "✅ EmotionAI API is running successfully"
else
    echo "❌ EmotionAI API failed to start"
    systemctl status emotion-ai
fi

# Log completion
echo "🚀 EC2 bootstrap completed at $(date)" | tee -a /var/log/emotion-ai-bootstrap.log