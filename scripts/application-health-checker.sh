
#!/bin/bash

APP_URL="https://52.66.255.103.nip.io:32177"

STATUS=$(curl -k -L --connect-timeout 5 --max-time 10 \
--resolve 52.66.255.103.nip.io:32177:172.31.9.29 \
-o /dev/null -s -w "%{http_code}" "$APP_URL")

echo "Checking Application Health..."

if [[ "$STATUS" == "200" ]]; then
    echo "Application is UP"
else
    echo "Application is DOWN"
fi
