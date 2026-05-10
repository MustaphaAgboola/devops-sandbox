#!/bin/bash

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --env) ENV_ID="$2"; shift ;;
        --mode) MODE="$2"; shift ;;
    esac
    shift
done

# Guard — never run against Nginx or daemon
if [[ "$ENV_ID" == "nginx" || "$ENV_ID" == "cleanup_daemon" ]]; then
    echo "ERROR: Cannot simulate outage on system containers"
    exit 1
fi

case $MODE in
    crash)
        docker kill sandbox-$ENV_ID
        ;;
    pause)
        docker pause sandbox-$ENV_ID
        ;;
    network)
        docker network disconnect sandbox-net-$ENV_ID sandbox-$ENV_ID
        ;;
    recover)
        docker unpause sandbox-$ENV_ID 2>/dev/null
        docker network connect sandbox-net-$ENV_ID sandbox-$ENV_ID 2>/dev/null
        docker start sandbox-$ENV_ID 2>/dev/null
        ;;
    stress)
        docker exec sandbox-$ENV_ID stress-ng --cpu 4 --timeout 60s
        ;;
    *)
        echo "Unknown mode: $MODE"
        exit 1
        ;;
esac

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Outage simulation: $MODE on $ENV_ID" >> logs/cleanup.log