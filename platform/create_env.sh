#!/bin/bash
NAME=$1
ENV_ID=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)
CREATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [ -z "$2" ]; then
    TTL=1800
else
    TTL=$2
fi

# Create Docker network
docker network create sandbox-net-$ENV_ID

# Find a free port
while true; do
    PORT=$(( ( RANDOM % 1000 ) + 8000 ))
    if ! lsof -i :$PORT > /dev/null 2>&1; then
        break
    fi
done

# Start the container
docker run -d \
  --name sandbox-$ENV_ID \
  --network sandbox-net-$ENV_ID \
  -p $PORT:3000 \
  --label sandbox.env=$ENV_ID \
  sandbox-app

# Write state file atomically
cat > envs/$ENV_ID.tmp << EOF
{
  "id": "$ENV_ID",
  "name": "$NAME",
  "ttl": $TTL,
  "port": $PORT,
  "status": "running",
  "created_at": "$CREATED_AT",
  "consecutive_failures": 0
}
EOF
mv envs/$ENV_ID.tmp envs/$ENV_ID.json

# Register Nginx route
cat > nginx/conf.d/$ENV_ID.conf << EOF
server {
    listen 80;
    server_name _;
    location /$ENV_ID {
        resolver 127.0.0.11 valid=30s;
        set \$upstream sandbox-$ENV_ID:3000;
        proxy_pass http://\$upstream;
    }
}
EOF
docker exec nginx nginx -s reload

echo "Env URL: http://localhost:$PORT TTL: $TTL seconds"