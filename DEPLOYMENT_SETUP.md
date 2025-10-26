# Deployment Setup Guide

This guide will help you set up CI/CD for your Calculator App using GitHub Actions without Docker.

## 🚀 Quick Setup Overview

1. **Server Setup** - Prepare your server
2. **GitHub Secrets** - Configure deployment credentials
3. **Repository Setup** - Configure branches and environments
4. **Deploy** - Push code to trigger deployment

---

## 1. 🖥️ Server Setup

### Option A: Automated Setup (Recommended)
Run this on your server:
```bash
chmod +x scripts/server-setup.sh
./scripts/server-setup.sh
```

### Option B: Manual Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip python3-venv git curl nginx

# Create directories
sudo mkdir -p /var/www/calculator-app
sudo chown -R $USER:$USER /var/www/calculator-app
```

---

## 2. 🔐 GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

### For Staging Environment:
```
STAGING_HOST=your-staging-server-ip
STAGING_USER=ubuntu
STAGING_SSH_KEY=your-private-ssh-key
STAGING_PORT=22
```

### For Production Environment:
```
PRODUCTION_HOST=your-production-server-ip
PRODUCTION_USER=ubuntu
PRODUCTION_SSH_KEY=your-private-ssh-key
PRODUCTION_PORT=22
```

### How to get SSH Key:
```bash
# On your local machine, generate SSH key
ssh-keygen -t rsa -b 4096 -c "calculator-app-deploy"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-server-ip

# Copy private key content for GitHub secret
cat ~/.ssh/id_rsa
```

---

## 3. 🌿 Repository Branch Setup

### Create Required Branches:
```bash
# Create develop branch for staging
git checkout -b develop
git push origin develop

# Main branch for production (already exists)
git checkout main
```

### GitHub Environments Setup:
1. Go to Repository → Settings → Environments
2. Create two environments:
   - **staging** (auto-deploy from `develop` branch)
   - **production** (manual approval for `main` branch)

---

## 4. 📁 Server Directory Structure

Your server should have this structure:
```
/var/www/
├── calculator-app/          # Production
│   ├── app.py
│   ├── static/
│   ├── requirements.txt
│   ├── venv/
│   └── logs/
└── calculator-app-staging/  # Staging
    ├── app.py
    ├── static/
    ├── requirements.txt
    ├── venv/
    └── logs/
```

---

## 5. 🚀 Deployment Workflow

### Automatic Deployments:

**Staging Deployment:**
```bash
# Push to develop branch
git checkout develop
git add .
git commit -m "Add new feature"
git push origin develop
# → Automatically deploys to staging server
```

**Production Deployment:**
```bash
# Merge to main branch
git checkout main
git merge develop
git push origin main
# → Requires manual approval, then deploys to production
```

### Manual Deployment:
```bash
# On your server
cd /var/www/calculator-app
chmod +x scripts/deploy-simple.sh
./scripts/deploy-simple.sh production
```

---

## 6. 🔍 Monitoring & Troubleshooting

### Check Application Status:
```bash
# Check if app is running
curl http://localhost:5000/health

# Check process
ps aux | grep python

# Check logs
tail -f /var/www/calculator-app/logs/production.log
```

### GitHub Actions Logs:
1. Go to your repository
2. Click "Actions" tab
3. Click on latest workflow run
4. Check logs for any errors

### Common Issues:

**SSH Connection Failed:**
- Verify server IP and SSH key
- Check firewall settings: `sudo ufw status`

**App Won't Start:**
- Check Python dependencies: `pip list`
- Check app logs: `tail -f logs/production.log`
- Verify port availability: `netstat -tlnp | grep 5000`

**Health Check Failed:**
- Ensure app is listening on correct port
- Check if firewall allows the port
- Verify Flask app has `/health` endpoint

---

## 7. 🌐 Domain Setup (Optional)

### Configure Nginx:
```bash
# Edit Nginx config
sudo nano /etc/nginx/sites-available/calculator-app

# Update server_name
server_name your-domain.com;

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### SSL Certificate (Let's Encrypt):
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

---

## 8. 📊 Success Indicators

✅ **CI Pipeline Passes:**
- Code formatting check
- Security scan
- Application health check

✅ **Deployment Succeeds:**
- SSH connection works
- Code pulls successfully
- Python environment sets up
- Application starts
- Health check passes

✅ **Application Works:**
- Website loads at `http://your-server-ip:5000`
- Calculator functions work
- Login and history features work

---

## 🆘 Need Help?

**Check these first:**
1. GitHub Actions logs
2. Server application logs
3. Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
4. System logs: `sudo journalctl -f`

**Test deployment locally:**
```bash
# Clone and test
git clone your-repo
cd calculator-app
chmod +x scripts/deploy-simple.sh
./scripts/deploy-simple.sh development
```