#!/bin/bash
# Server Monitoring Script

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85

# Get system metrics
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)

# NGINX status
NGINX_STATUS=$(systemctl is-active nginx)

echo "=== Server Monitoring Report ==="
echo "Timestamp: $TIMESTAMP"
echo "Hostname: $HOSTNAME"
echo "--------------------------------"
echo "CPU Usage: ${CPU_USAGE}%"
echo "Memory Usage: ${MEMORY_USAGE}%"
echo "Disk Usage: ${DISK_USAGE}%"
echo "Load Average: $LOAD_AVERAGE"
echo "NGINX Status: $NGINX_STATUS"
echo "================================"

# Check thresholds and alert
if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
    echo "WARNING: CPU usage is above ${CPU_THRESHOLD}%"
fi

if [ "$MEMORY_USAGE" -gt "$MEMORY_THRESHOLD" ]; then
    echo "WARNING: Memory usage is above ${MEMORY_THRESHOLD}%"
fi

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    echo "WARNING: Disk usage is above ${DISK_THRESHOLD}%"
fi

if [ "$NGINX_STATUS" != "active" ]; then
    echo "CRITICAL: NGINX is not running!"
    # Attempt to restart
    systemctl start nginx
fi

# Log to syslog
logger -t monitoring "CPU: ${CPU_USAGE}% | MEM: ${MEMORY_USAGE}% | DISK: ${DISK_USAGE}% | NGINX: $NGINX_STATUS"
