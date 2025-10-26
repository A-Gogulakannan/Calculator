#!/bin/bash

# Server Setup Script for Calculator App
# Run this on your server to prepare it for deployment

set -e

echo "🚀 Setting up server for Calculator App deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    nginx \
    supervisor \
    ufw

# Create application user (optional, for better security)
echo "👤 Creating application user..."
sudo useradd -m -s /bin/bash calculator || echo "User already exists"

# Create application directories
echo "📁 Creating application directories..."
sudo mkdir -p /var/www/calculator-app
sudo mkdir -p /var/www/calculator-app-staging
sudo mkdir -p /var/log/calculator-app

# Set permissions
echo "🔐 Setting permissions..."
sudo chown -R $USER:$USER /var/www/calculator-app
sudo chown -R $USER:$USER /var/www/calculator-app-staging
sudo chown -R $USER:$USER /var/log/calculator-app

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 5000  # Production
sudo ufw allow 5001  # Staging
sudo ufw --force enable

# Configure Nginx (basic setup)
echo "🌐 Configuring Nginx..."
sudo tee /etc/nginx/sites-available/calculator-app > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;  # Change this to your domain

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }
}

# Staging server (optional)
server {
    listen 80;
    server_name staging.your-domain.com;  # Change this to your staging domain

    location / {
        proxy_pass http://localhost:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/calculator-app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configure Supervisor for process management
echo "👨‍💼 Configuring Supervisor..."
sudo tee /etc/supervisor/conf.d/calculator-prod.conf > /dev/null <<EOF
[program:calculator-prod]
command=/var/www/calculator-app/venv/bin/python app.py
directory=/var/www/calculator-app
user=$USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/calculator-app/production.log
environment=FLASK_ENV=production,PORT=5000
EOF

sudo tee /etc/supervisor/conf.d/calculator-staging.conf > /dev/null <<EOF
[program:calculator-staging]
command=/var/www/calculator-app-staging/venv/bin/python app.py
directory=/var/www/calculator-app-staging
user=$USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/calculator-app/staging.log
environment=FLASK_ENV=staging,PORT=5001
EOF

# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update

# Create deployment key directory
echo "🔑 Setting up deployment keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "✅ Server setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Add your GitHub deploy key to ~/.ssh/"
echo "2. Clone your repository to /var/www/calculator-app"
echo "3. Update Nginx server names in /etc/nginx/sites-available/calculator-app"
echo "4. Run your deployment script"
echo ""
echo "🔧 Useful commands:"
echo "  - Check app status: sudo supervisorctl status"
echo "  - Restart app: sudo supervisorctl restart calculator-prod"
echo "  - View logs: tail -f /var/log/calculator-app/production.log"
echo "  - Check Nginx: sudo nginx -t && sudo systemctl status nginx"