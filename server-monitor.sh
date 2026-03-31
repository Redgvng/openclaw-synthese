#!/bin/bash
# LexiClaw Server Monitor - checks every 5 minutes
while true; do
  TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M UTC")
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 2>/dev/null)
  
  if [ "$HTTP_CODE" != "200" ]; then
    echo "[$TIMESTAMP] Server DOWN (HTTP $HTTP_CODE) - restarting..."
    cd /tmp/lexiclaw-arch && npm run dev > /tmp/lexiclaw-dev.log 2>&1 &
    sleep 10
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 2>/dev/null)
    echo "[$TIMESTAMP] Restart result: HTTP $HTTP_CODE"
  else
    echo "[$TIMESTAMP] Server OK (HTTP $HTTP_CODE)"
  fi
  
  sleep 300  # 5 minutes
done
