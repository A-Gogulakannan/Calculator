#!/bin/bash

# Calculator App Status Check Script

echo "📊 Calculator App Status Check"
echo "================================"

# Check if processes are running
echo "🔍 Checking running processes..."
PROD_PID=$(pgrep -f "python.*app.py" | head -1)
if [ ! -z "$PROD_PID" ]; then
    echo "✅ Production app is running (PID: $PROD_PID)"
else
    echo "❌ Production app is not running"
fi

# Check ports
echo ""
echo "🌐 Checking ports..."
if netstat -tlnp 2>/dev/null | grep -q ":5000 "; then
    echo "✅ Port 5000 (production) is in use"
else
    echo "❌ Port 5000 (production) is not in use"
fi

if netstat -tlnp 2>/dev/null | grep -q ":5001 "; then
    echo "✅ Port 5001 (staging) is in use"
else
    echo "❌ Port 5001 (staging) is not in use"
fi

# Health checks
echo ""
echo "🏥 Health checks..."
if curl -f -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Production health check passed"
else
    echo "❌ Production health check failed"
fi

if curl -f -s http://localhost:5001/health > /dev/null 2>&1; then
    echo "✅ Staging health check passed"
else
    echo "❌ Staging health check failed"
fi

# Check logs
echo ""
echo "📋 Recent log entries..."
if [ -f "/var/www/calculator-app/logs/production.log" ]; then
    echo "Last 5 lines from production log:"
    tail -5 /var/www/calculator-app/logs/production.log
else
    echo "No production log file found"
fi

# System resources
echo ""
echo "💻 System resources..."
echo "Memory usage:"
free -h | grep -E "Mem|Swap"
echo "Disk usage:"
df -h / | tail -1

echo ""
echo "✨ Status check completed!"