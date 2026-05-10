#!/bin/bash
while true; do
    for file in envs/*.json; do
        PORT=$(jq -r '.port' $file)
        ID=$(jq -r '.id' $file)
        RESPONSE=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" http://localhost:$PORT/health)
        STATUS=$(echo $RESPONSE | awk '{print $1}')
        LATENCY=$(echo $RESPONSE | awk '{print $2}')
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Status: $STATUS Latency: $LATENCY" >> logs/$ID/health.log
        FAILURES=$(jq -r '.consecutive_failures' $file)
        if [ "$STATUS" != "200" ]; then
            FAILURES=$((FAILURES + 1))
            jq ".consecutive_failures = $FAILURES" $file > $file.tmp && mv $file.tmp $file
            if [ $FAILURES -ge 3 ]; then
                jq '.status = "degraded"' $file > $file.tmp && mv $file.tmp $file
                echo "WARNING: env $ID is degraded"
            fi
        else
            jq '.consecutive_failures = 0' $file > $file.tmp && mv $file.tmp $file
        fi
    done
    sleep 30
done