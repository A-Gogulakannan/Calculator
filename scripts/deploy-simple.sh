#!/bin/bash

# Simple Calculator App Deployment Script (No Docker)
# Usage: ./deploy-simple.sh [environment]

set -e

ENVIRONMENT=${1:-production}
APP_NAME="calculator-app"

# Configuration based on environment
case ${ENVIRONMENT} in
    "production")
        APP_DIR="/var/www/${APP_NAME}"
        PORT=5000
        BRANCH="main"
        ;;
    "staging")
        APP_DIR="/var/www/${APP_NAME}-staging"
        PORT=5001
        BRANCH="develop"
        ;;
    "development")
        APP_DIR="$(pwd)"
        PORT=5000
        BRANCH="develop"
        ;;
    *)
        echo "❌ Unknown environment: ${ENVIRONMENT}"
        echo "Available environments: production, staging, development"
        exit 1
        ;;
esac

VENV_DIR="${APP_DIR}/venv"
LOG_DIR="${APP_DIR}/logs"
LOG_FILE="${LOG_DIR}/${ENVIRONMENT}.log"
PID_FILE="${APP_DIR}/${ENVIRONMENT}.pid"

echo "🚀 Starting deployment to ${ENVIRONMENT}..."
echo "📍 App directory: ${APP_DIR}"
echo "🌐 Port: ${PORT}"
echo "🌿 Branch: ${BRANCH}"

# Create directories if they don't exist
mkdir -p ${LOG_DIR}

# Step 1: Pull the latest code (skip for development)
if [ "${ENVIRONMENT}" != "development" ]; then
    echo "📥 Pulling latest code..."
    cd ${APP_DIR}
    git fetch origin
    git checkout ${BRANCH}
    git pull origin ${BRANCH}
else
    echo "🔧 Using current directory for development..."
    cd ${APP_DIR}
fi

# Step 2: Setup Python environment
echo "🐍 Setting up Python environment..."
if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv ${VENV_DIR}
fi
source ${VENV_DIR}/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Step 3: Stop any running app instance
echo "🛑 Stopping existing app..."
if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat ${PID_FILE})
    if kill -0 ${OLD_PID} 2>/dev/null; then
        echo "Stopping process ${OLD_PID}..."
        kill ${OLD_PID}
        sleep 3
    fi
    rm -f ${PID_FILE}
fi

# Also kill by process name as backup
pkill -f "python.*app.py" || true
sleep 2

# Step 4: Start new instance
echo "🚀 Starting new app instance..."
export FLASK_ENV=${ENVIRONMENT}
export PORT=${PORT}

if [ "${ENVIRONMENT}" = "development" ]; then
    # Run in foreground for development
    python app.py
else
    # Run in background for production/staging
    nohup python app.py > ${LOG_FILE} 2>&1 &
    NEW_PID=$!
    echo ${NEW_PID} > ${PID_FILE}
    echo "📝 Process ID: ${NEW_PID}"
fi

# Step 5: Health check (skip for development since it runs in foreground)
if [ "${ENVIRONMENT}" != "development" ]; then
    echo "🔍 Checking health..."
    sleep 10
    
    MAX_ATTEMPTS=30
    ATTEMPT=1
    
    while [ ${ATTEMPT} -le ${MAX_ATTEMPTS} ]; do
        if curl -f http://localhost:${PORT}/health > /dev/null 2>&1; then
            echo "✅ App is running successfully on port ${PORT}!"
            break
        fi
        
        echo "⏳ Attempt ${ATTEMPT}/${MAX_ATTEMPTS} - waiting for app to start..."
        sleep 5
        ((ATTEMPT++))
    done
    
    if [ ${ATTEMPT} -gt ${MAX_ATTEMPTS} ]; then
        echo "❌ App health check failed after ${MAX_ATTEMPTS} attempts!"
        echo "📋 Last 20 lines of log:"
        tail -20 ${LOG_FILE}
        exit 1
    fi
    
    echo "🎉 Deployment to ${ENVIRONMENT} completed successfully!"
    echo "📊 App status:"
    echo "   - Environment: ${ENVIRONMENT}"
    echo "   - Port: ${PORT}"
    echo "   - PID: $(cat ${PID_FILE})"
    echo "   - Log: ${LOG_FILE}"
fi