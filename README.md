# devops-sandbox

A self-service platform for spinning up isolated temporary environments with chaos engineering capabilities.

## Architecture

```
                    ┌─────────────┐
                    │   Client    │
                    └──────┬──────┘
                           │ HTTP
                    ┌──────▼──────┐
                    │    Nginx    │ (port 80)
                    └──────┬──────┘
                           │ proxy_pass
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼─────┐   ┌──────▼─────┐  ┌──────▼─────┐
   │ sandbox-   │   │ sandbox-   │  │ sandbox-   │
   │ env1       │   │ env2       │  │ env3       │
   └────────────┘   └────────────┘  └────────────┘
          │
   ┌──────▼──────┐        ┌─────────────────┐
   │  Control   │        │ Cleanup Daemon  │
   │  API :5000 │        │ (every 60s)     │
   └────────────┘        └─────────────────┘
          │                       │
   ┌──────▼───────────────────────▼──────┐
   │           envs/*.json               │
   │         (state files)               │
   └─────────────────────────────────────┘
```

## Prerequisites

- Docker
- Python 3 + Flask (`pip install flask`)
- `jq`, `curl`, `shuf`, `ss`

## Quick Start

```bash
git clone https://github.com/yourname/devops-sandbox
cd devops-sandbox
cp .env.example .env
mkdir -p envs logs/archived nginx/conf.d
make up
make create
```

## Demo Walkthrough

```bash
# 1. Start the platform
make up

# 2. Create an environment
make create
# Enter name: my-app
# Enter TTL: 300

# 3. Check health
make health

# 4. Simulate an outage
make simulate ENV=<env-id> MODE=crash

# 5. Observe degraded status
make health

# 6. Recover
make simulate ENV=<env-id> MODE=recover

# 7. Destroy manually or wait for auto-destroy
make destroy ENV=<env-id>
```

## Known Limitations

- Port collisions possible under heavy load
- No persistent storage for env state across host reboots
- Log shipping uses Approach A (simple) — no log aggregator
- No TLS/HTTPS support
- Single VM only — no multi-host support
