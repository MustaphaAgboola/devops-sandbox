#!/bin/bash
while true; do
    for file in envs/*.json; do
        [ -f "$file" ] || continue
        TTL=$(jq -r '.ttl' "$file" 2>/dev/null)
        CREATED_AT=$(jq -r '.created_at' "$file" 2>/dev/null)
        ENV_ID=$(basename "$file" .json)
        
        # Skip if values are missing or null
        [ -z "$TTL" ] || [ "$TTL" = "null" ] && continue
        [ -z "$CREATED_AT" ] || [ "$CREATED_AT" = "null" ] && continue
        
        NOW=$(date -u +%s)
        CREATED_TS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CREATED_AT" +%s 2>/dev/null)
        
        [ -z "$CREATED_TS" ] && continue
        
        if (( NOW > CREATED_TS + TTL )); then
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Destroying env $ENV_ID — TTL expired" >> logs/cleanup.log
            ./platform/destroy_env.sh "$ENV_ID"
        fi
    done
    sleep 60
done