# Homelab

## Summary

Documentation of homelab infrastructure, including docker compose configs, Proxmox VM/LXC configs, and setup guides.

## Hosts

| Host | Hardware                          | Purpose                     |
|------|-----------------------------------|-----------------------------|
| PVE  | Ryzen 9 7900, 96 GB RAM, 1 TB NVMe | Primary Proxmox node       |
| Cube | Intel (UHD 630), 32 GB RAM, 2x 1 TB NVMe | Secondary Proxmox node |
| hetzvps | Hetzner cax11 (2 vCPU ARM, 4 GB RAM) | Tailscale exit node (NixOS) |

## Services

| Name            | Type | Host    | Purpose                                    |
|-----------------|------|---------|--------------------------------------------|
| arr             | LXC  | Cube    | Media automation (*arr stack, Overseerr)   |
| home-automation | LXC  | Cube    | Home automation                            |
| proxy           | LXC  | PVE     | Nginx Proxy Manager                        |
| technitium      | LXC  | PVE     | Technitium DNS — resolver, ad blocking, local zone (192.168.1.5) |
| mcphub          | LXC  | PVE     | MCPHub, Graphiti, Open Wearables           |
| macos-tahoe     | VM   | PVE     | macOS Tahoe — Apple MCP servers            |
| unraid          | VM   | PVE     | Unraid NAS, media storage                  |
| plex            | LXC  | Cube    | Plex Media Server (iGPU transcoding)       |
| uptime-kuma     | LXC  | PVE     | Uptime Kuma monitoring                     |
| dockhand        | LXC  | PVE     | Dockhand Docker management UI              |
| palworld        | LXC  | PVE     | Palworld dedicated server                  |

## Networking

Technitium DNS (192.168.1.5) serves the LAN (via Unifi DHCP) and the tailnet
(global nameserver) — recursive resolution, ad blocking, and a local
`shaneplunkett.com` zone whose wildcard points at Nginx Proxy Manager for
TLS and per-service routing. The pve node is a Tailscale subnet router, so
tailnet devices reach LAN addresses directly. See
[docs/pve/technitium-research.md](docs/pve/technitium-research.md).

## Backups

MCPHub and vex-brain data backed up every 4 hours, and Technitium DNS config
daily, via restic to a Hetzner Storage Box in Helsinki. See
[docs/hetzner/backups.md](docs/hetzner/backups.md).

## Structure

Folder per host, subfolders per resource on host. Each subfolder has a README and docker compose if relevant. Hetzner cloud resources managed via Terraform in `terraform/`.
