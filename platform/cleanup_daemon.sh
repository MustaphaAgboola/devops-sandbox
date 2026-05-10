#!/bin/bash
while true; do
    for file in envs/*.json; do
        TTL=$(jq -r '.ttl' $file)
        CREATED_AT=$(jq -r '.created_at' $file)
        NOW=$(date +%s)
        CREATED_TS=$(date -d "$CREATED_AT" +%s)
        ENV_ID=$(basename $file .json)
        if (( $NOW > $CREATED_TS + $TTL )); then
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Destroying env $ENV_ID — TTL expired" >> logs/cleanup.log
            ./destroy_env.sh $ENV_ID
        fi
    done
    sleep 60
done