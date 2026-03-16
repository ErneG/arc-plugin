---
name: tide:setup postgres-mcp
description: >
  Add Postgres MCP Pro for index tuning, EXPLAIN ANALYZE, slow query detection, and health checks.
  Triggers: "tide setup postgres", "setup database tools", "add postgres mcp".
allowed-tools: Read, Write, Edit, Bash
---

# /tide:setup postgres-mcp — Database Inspection Tools

Adds crystaldba/postgres-mcp for deep database analysis.

## Process

1. Pull Docker image:
   ```bash
   docker pull crystaldba/postgres-mcp
   ```

2. Add to `.mcp.json` (create if missing):
   ```json
   {
     "mcpServers": {
       "postgres-pro": {
         "command": "docker",
         "args": ["run", "-i", "--rm", "crystaldba/postgres-mcp",
                  "--access-mode=unrestricted",
                  "--connection-url", "<DATABASE_URL from .env>"]
       }
     }
   }
   ```

3. Read DATABASE_URL from .env and substitute into the config.

## What it enables

- `EXPLAIN ANALYZE` on any query
- Slow query detection via `pg_stat_statements`
- Index health and tuning recommendations
- Connection utilization monitoring
- Vacuum health checks
- Hypothetical index simulation
