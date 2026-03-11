# Arr LXC

## Summary

Alpine LXC running the full media automation stack via Docker, managed with Dockge. Mounts media and appdata from Unraid.

- **CTID:** 103
- **Hostname:** arr
- **IP:** 192.168.1.90 (static)
- **OS:** Alpine
- **Cores:** 2
- **RAM:** 4 GB
- **Swap:** 1 GB
- **Disk:** 40 GB (local-lvm)

## Proxmox Config

`/etc/pve/lxc/103.conf`:

```
arch: amd64
cores: 2
features: nesting=1
hostname: arr
memory: 4096
mp0: /mnt/pve/unraid-media,mp=/mnt/media
mp1: /mnt/pve/unraid-appdata,mp=/mnt/appdata
mp2: /mnt/pve/unraid-programs,mp=/mnt/programs
net0: name=eth0,bridge=vmbr0,firewall=1,gw=192.168.1.1,hwaddr=BC:24:11:D0:E3:0D,ip=192.168.1.90/24,type=veth
ostype: alpine
rootfs: local-lvm:vm-103-disk-0,size=40G
swap: 1024
unprivileged: 1
```

Key config notes:
- Static IP `192.168.1.90` (other services need stable addresses for this)
- Three bind mounts from Proxmox-managed NFS storage pools:
  - `unraid-media` → `/mnt/media` — media library
  - `unraid-appdata` → `/mnt/appdata` — app configs
  - `unraid-programs` → `/mnt/programs` — programs/software share
- `nesting=1` for Docker-in-LXC

## Services

All containers use PUID=99/PGID=100 (Unraid nobody/users) for file permissions compatibility.

### Media Management
- **Radarr** — movie management (port 7878)
- **Sonarr TV** — TV show management, develop branch (port 8989)
- **Anime Sonarr** — separate Sonarr instance for anime (port 8990)
- **Prowlarr** — indexer management (port 9696)
- **Seerr** — request management UI (port 5055)

### Downloads
- **Deluge** — torrent client (port 8112 web UI, 6881 data)
- **SABnzbd** — usenet client (port 8080)

### Streaming
- **MiniDLNA** — DLNA server for `/mnt/programs` (host network mode)

### Management
- **Dockge** — Docker Compose management UI (port 5001)

## Compose Files

- **Arr stack:** `/opt/stacks/arr/compose.yaml`
- **Dockge:** `/opt/dockge/compose.yaml`

Dockge manages the stacks via its UI at http://192.168.1.90:5001.
