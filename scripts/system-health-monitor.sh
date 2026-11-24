
#!/bin/bash

echo "===== System Health Monitoring ====="
echo "Date: $(date)"
echo ""

# CPU Usage
CPU=$(vmstat 1 2 | awk 'END {print 100-$15}')
echo "CPU Usage: $CPU%"

# Memory Usage
MEMORY=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
echo "Memory Usage: $MEMORY%"

# Disk Usage
DISK=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
echo "Disk Usage: $DISK%"

# Running Processes
PROCESSES=$(ps -e --no-headers | wc -l)
echo "Running Processes: $PROCESSES"

echo ""
echo "===== Health Alerts ====="

# CPU Alert
if (( $(echo "$CPU > 80" | bc -l) )); then
    echo "ALERT: High CPU usage!"
else
    echo "OK: CPU usage is normal."
fi

# Memory Alert
if (( MEMORY > 80 )); then
    echo "ALERT: High memory usage!"
else
    echo "OK: Memory usage is normal."
fi

# Disk Alert
if (( DISK > 80 )); then
    echo "ALERT: High disk usage!"
else
    echo "OK: Disk usage is normal."
fi

# Process Count Alert
if (( PROCESSES > 250 )); then
    echo "ALERT: High number of running processes!"
else
    echo "OK: Process count is normal."
fi

echo ""
echo "Health check completed."
