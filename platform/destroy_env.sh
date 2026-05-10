#!/bin/bash
ENV_ID=$1

# Stop and remove container
docker stop sandbox-$ENV_ID
docker rm sandbox-$ENV_ID

# Remove Docker network
docker network rm sandbox-net-$ENV_ID

# Remove Nginx config and reload
rm nginx/conf.d/$ENV_ID.conf
docker exec nginx nginx -s reload

# Archive logs
mkdir -p logs/archived
mv logs/$ENV_ID/ logs/archived/$ENV_ID/ 2>/dev/null || true

# Delete state file
rm envs/$ENV_ID.json