#!/bin/bash

# Calculator App Deployment Script
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
APP_NAME="calculator-app"
DOCKER_IMAGE="${APP_NAME}:latest"

echo "🚀 Starting deployment to ${ENVIRONMENT}..."

# Function to check if service is healthy
check_health() {
    local url=$1
    local max_attempts=30
    local attempt=1
    
    echo "🔍 Checking health at ${url}..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "${url}/health" > /dev/null; then
            echo "✅ Service is healthy!"
            return 0
        fi
        
        echo "⏳ Attempt ${attempt}/${max_attempts} - waiting for service..."
        sleep 10
        ((attempt++))
    done
    
    echo "❌ Health check failed after ${max_attempts} attempts"
    return 1
}

# Pull latest image
echo "📥 Pulling latest Docker image..."
docker pull ${DOCKER_IMAGE}

# Stop existing container
echo "🛑 Stopping existing container..."
docker stop ${APP_NAME}-${ENVIRONMENT} 2>/dev/null || true
docker rm ${APP_NAME}-${ENVIRONMENT} 2>/dev/null || true

# Deploy based on environment
case ${ENVIRONMENT} in
    "production")
        echo "🏭 Deploying to production..."
        docker run -d \
            --name ${APP_NAME}-${ENVIRONMENT} \
            -p 5000:5000 \
            -e FLASK_ENV=production \
            -v /data/calculator:/app/data \
            --restart unless-stopped \
            ${DOCKER_IMAGE}
        
        check_health "http://localhost:5000"
        ;;
        
    "staging")
        echo "🧪 Deploying to staging..."
        docker run -d \
            --name ${APP_NAME}-${ENVIRONMENT} \
            -p 5001:5000 \
            -e FLASK_ENV=staging \
            --restart unless-stopped \
            ${DOCKER_IMAGE}
        
        check_health "http://localhost:5001"
        ;;
        
    "development")
        echo "🔧 Deploying to development..."
        docker-compose up -d
        check_health "http://localhost:5000"
        ;;
        
    *)
        echo "❌ Unknown environment: ${ENVIRONMENT}"
        echo "Available environments: production, staging, development"
        exit 1
        ;;
esac

echo "🎉 Deployment to ${ENVIRONMENT} completed successfully!"

# Clean up old images
echo "🧹 Cleaning up old Docker images..."
docker image prune -f

echo "✨ Deployment script finished!"