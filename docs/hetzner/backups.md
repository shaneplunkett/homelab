# Storage Box — Backups

## Summary

Hetzner Storage Box used as the restic backup target for MCPHub data. Accessed via SFTP from the mcphub LXC.

- **Storage type:** bx11 (Helsinki)
- **Credentials:** managed by Terraform (`random_password.storage_box`), stored in Terraform Cloud state
- **Delete protection:** enabled

## Restic

**What's backed up:**
- PostgreSQL dump (mcphub database)
- Neo4j data volume (hot copy)
- MCP memory, config files, patches
- `.env` (as `env.backup`)
- Google Workspace MCP credentials

**Schedule:** every 4 hours via cron

**Retention:** keep last 6, 7 daily, 4 weekly

**Monitoring:** push heartbeat to Uptime Kuma on success — alerts after 2 missed beats (8 hours).

## SSH Access

SSH key registered with the storage box via Terraform. Known hosts configured for the storage box SSH port.

## Gotchas

- **Cron is ephemeral** — set in crontab on the Alpine LXC, not declaratively managed. Will be lost if the container is rebuilt.
- **SFTP paths must be relative** — use `./backups` not `/backups`.
- **SSH port** — Hetzner storage boxes use a non-standard SSH port (not 22).
