# Storage Box — Backups

## Summary

Hetzner Storage Box used as the restic backup target for MCPHub data. Accessed via SFTP from the mcphub LXC (CTID 105).

- **Server:** REDACTED.your-storagebox.de
- **Username:** REDACTED_USER
- **SSH port:** 23
- **Storage type:** bx11 (Helsinki)
- **Password:** managed by Terraform (`random_password.storage_box`), stored in Terraform Cloud state
- **Delete protection:** enabled

## Restic

**Repo:** `sftp:REDACTED_USER@REDACTED.your-storagebox.de:./backups` (relative path required — absolute paths don't work on Hetzner storage boxes)

**Password:** stored at `REDACTED_PATH` on LXC 105, also in agenix as `restic-password.age`.

**What's backed up:**
- PostgreSQL dump (mcphub database)
- Neo4j data volume (hot copy)
- `memory.jsonl` (MCP memory)
- `docker-compose.yml`, `mcp_settings.json`, `graphiti-config.yaml`
- `.env` (as `env.backup`)
- `patches/` directory
- Google Workspace MCP credentials

**Schedule:** every 4 hours (`0 */4 * * *` in `/etc/crontabs/root` on LXC 105)

**Retention:** keep last 6, 7 daily, 4 weekly

## Backup Script

Located at `/opt/mcphub/backup.sh` on LXC 105. Runs as root.

```bash
/opt/mcphub/backup.sh
```

## SSH Access

Root SSH key on LXC 105 (`/root/.ssh/id_ed25519`) is registered with the storage box via Terraform. Known hosts configured for port 23.

## Gotchas

- **Cron is ephemeral** — the cron job is set in `/etc/crontabs/root` on the Alpine LXC, not declaratively managed. Will be lost if the container is rebuilt.
- **SFTP paths must be relative** — use `./backups` not `/backups`.
- **SSH port 23** — not the default 22.
