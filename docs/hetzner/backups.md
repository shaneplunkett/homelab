# Storage Box — Backups

## Summary

Hetzner Storage Box used as the restic backup target for MCPHub and vex-brain data. Accessed via SFTP from the mcphub LXC.

- **Storage type:** bx11 (Helsinki)
- **Credentials:** managed by Terraform (`random_password.storage_box`), stored in Terraform Cloud state
- **Delete protection:** enabled

## Restic

**What's backed up:**
- PostgreSQL dump (mcphub database)
- PostgreSQL custom-format dump (`pg_dump -Fc`) for vex-brain
- `pg_restore -l` table of contents and SHA-256 checksum for the vex-brain dump
- Neo4j data volume (hot copy)
- MCP memory, config files, patches
- `.env` (as `env.backup`)
- vex-brain compose/env config
- Google Workspace MCP credentials

**Schedule:** every 4 hours via cron

**Retention:** keep last 6, 7 daily, 4 weekly

**Monitoring:** push heartbeat to Uptime Kuma on success and an explicit down heartbeat on script failure.

**Script:** repo-managed at `stacks/pve/mcphub-lxc/backup.sh`, installed on the LXC as `/opt/mcphub/backup.sh`.

## Restic — Technitium

**What's backed up:**
- Technitium config zip exported live via the API (zones, DNS settings, auth, apps, DHCP scopes; excludes blocklist cache/logs/stats)
- Raw copy of the `technitium_config` Docker volume
- Compose file and admin password file

**Schedule:** daily at 03:30 via cron on the technitium LXC

**Retention:** 7 daily, 4 weekly (tag `technitium`)

**Script:** repo-managed at `stacks/pve/technitium-lxc/backup.sh`, installed on the LXC as `/opt/technitium/backup.sh`. Same restic repo and password as mcphub; the LXC has its own SSH key on the storage box.

## SSH Access

SSH key registered with the storage box via Terraform. Known hosts configured for the storage box SSH port. The mcphub and technitium LXCs each have their own root SSH keys appended to the box's `authorized_keys` out-of-band (Terraform ignores `ssh_keys` changes).

## Gotchas

- **Cron is ephemeral** — set in crontab on the Alpine LXC, not declaratively managed. Will be lost if the container is rebuilt.
- **SFTP paths must be relative** — use `./backups` not `/backups`.
- **SSH port** — Hetzner storage boxes use a non-standard SSH port (not 22).
- **The LXC is still a scheduling dependency** — the offsite restic repo survives LXC loss, but new logical dumps only happen while the LXC and Docker stack are healthy. Add a Proxmox-host backup layer for CT 105 to cover full-container recovery.
