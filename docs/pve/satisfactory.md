# Satisfactory Dedicated Server LXC

## Summary

Alpine LXC container on PVE running the Satisfactory dedicated server (experimental branch) via the `wolveix/satisfactory-server` Docker image.

- **Hostname:** satisfactory
- **OS:** Alpine 3.22
- **Cores:** 6
- **RAM:** 24 GB
- **Swap:** 4 GB
- **Disk:** 50 GB (local-lvm)
- **Network:** DHCP on `vmbr0`, ports `7777/udp` (game traffic) + `7777/tcp` (HTTPS Server API)
- **Boot on start:** yes
- **Branch:** experimental (`STEAMBETA=true`)

## Connecting

LAN-only — connect from the in-game server browser using the LXC's IP and port `7777`.

```
satisfactory.<LXC-IP>:7777
```

Find the IP on the PVE host:

```bash
ssh shane@pve "sudo pct exec $(sudo pct list | awk '/satisfactory/ {print $1}') -- ip -4 addr show eth0"
```

## Stack

`stacks/pve/satisfactory-lxc/docker-compose.yml` — wolveix image, single UDP port 7777.

Key env knobs:

| Var | Value | Why |
|---|---|---|
| `STEAMBETA` | `true` | Opt into the experimental branch |
| `AUTOPAUSE` | `true` | Server idles CPU when no players are connected |
| `AUTOSAVEONDISCONNECT` | `true` | Save when last player leaves |
| `AUTOSAVEINTERVAL` | `300` | Autosave every 5 minutes |
| `AUTOSAVENUM` | `10` | Keep 10 rolling autosaves |
| `MAXPLAYERS` | `8` | Cap concurrent players |
| `SKIPUPDATE` | `false` | Pull latest experimental on container restart |

To pin a specific experimental build (avoid an update mid-session):

```bash
docker compose exec satisfactory env | grep SKIPUPDATE  # confirm
# Edit docker-compose.yml: SKIPUPDATE: "true"
docker compose up -d
```

## Bootstrap (first deploy)

After Terraform creates the LXC:

```bash
# 1. SSH to the LXC via PVE
ssh shane@pve "sudo pct exec $(sudo pct list | awk '/satisfactory/ {print $1}') -- sh"

# Inside the LXC:
apk add --no-cache docker docker-compose git
rc-update add docker default
service docker start

# Pull stack from this repo
mkdir -p /opt/satisfactory && cd /opt/satisfactory
# (Copy stacks/pve/satisfactory-lxc/docker-compose.yml here, e.g. via scp or git)
docker compose up -d
docker compose logs -f
```

First boot downloads the server (~15 GB) and applies the experimental beta — give it ~10 minutes before connecting.

## Saves

Saves persist at `/opt/satisfactory/config/gamefiles/FactoryGame/Saved/SaveGames/` inside the LXC.

## Backups

Saves are pushed to the Hetzner Storage Box (Helsinki) via restic over SFTP, every 6 hours.

**What's backed up:**

- `/opt/satisfactory/config/gamefiles/FactoryGame/Saved/SaveGames/` (all save slots)
- `/opt/satisfactory/config/gamefiles/FactoryGame/Saved/Config/` (server settings)
- `docker-compose.yml`

**Schedule:** every 6 hours via cron

**Retention:** keep last 8, 14 daily, 4 weekly

**Setup:**

```bash
apk add --no-cache restic openssh-client

# Bootstrap repo (one-time)
export RESTIC_REPOSITORY="sftp:u<storage-box-id>@u<storage-box-id>.your-storagebox.de:./satisfactory"
export RESTIC_PASSWORD="<long random string — store somewhere safe>"
restic init

# Backup script
cat > /usr/local/bin/satisfactory-backup.sh <<'SH'
#!/bin/sh
set -eu
export RESTIC_REPOSITORY="sftp:u<storage-box-id>@u<storage-box-id>.your-storagebox.de:./satisfactory"
export RESTIC_PASSWORD_FILE=/root/.restic-password
SAVES=/opt/satisfactory/config/gamefiles/FactoryGame/Saved
restic backup \
  "$SAVES/SaveGames" \
  "$SAVES/Config" \
  /opt/satisfactory/docker-compose.yml \
  --tag satisfactory \
  --host satisfactory
restic forget --keep-last 8 --keep-daily 14 --keep-weekly 4 --prune
# Heartbeat to uptime-kuma
curl -sfm 10 --retry 3 "$KUMA_URL" >/dev/null
SH
chmod +x /usr/local/bin/satisfactory-backup.sh

# Cron — every 6 hours
echo "0 */6 * * * /usr/local/bin/satisfactory-backup.sh >> /var/log/satisfactory-backup.log 2>&1" | crontab -
```

**Note:** cron is ephemeral (alpine LXC) — re-add after a rebuild.

## Resource notes

- 24 GB RAM is comfortable for a single late-game save with a small group. Bump if your factory grows obscene.
- 6 cores keeps tick rate steady; Satisfactory's sim is largely single-threaded but worker threads benefit from extra cores.
- 50 GB disk: ~15 GB binaries + room for saves + autosave history + headroom.

## Gotchas

- **Two ports on 7777** — UDP for game traffic, TCP for the HTTPS Server API. Forwarding only UDP gives "Failed to Connect to the Server API". Since v1.0 the old 15000/15777 split is gone — don't forward those.
- **First boot is slow** — wolveix downloads via SteamCMD, can take 10+ min on first run.
- **Experimental drift** — when an experimental patch lands, all clients must update before reconnecting. Pin `SKIPUPDATE=true` for predictability mid-session.
- **No client port-forward needed** for LAN-only play.
