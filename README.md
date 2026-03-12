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

| Name          | Type | Host    | Purpose                                    |
|---------------|------|---------|--------------------------------------------|
| arr           | LXC  | Cube    | Media automation (*arr stack, Overseerr)   |
| proxy         | LXC  | PVE     | Nginx Proxy Manager                       |
| mcphub        | LXC  | PVE     | MCPHub, Graphiti, Open Wearables           |
| macos-tahoe   | VM   | PVE     | macOS Tahoe — Apple MCP servers            |
| plex          | LXC  | Cube    | Plex Media Server (iGPU transcoding)      |
| uptime-kuma   | LXC  | PVE     | Uptime Kuma monitoring                    |
| dockhand      | LXC  | PVE     | Dockhand Docker management UI             |

## Backups

MCPHub data backed up every 4 hours via restic to a Hetzner Storage Box in Helsinki. See [docs/hetzner/backups.md](docs/hetzner/backups.md).

## Structure

Folder per host, subfolders per resource on host. Each subfolder has a README and docker compose if relevant. Hetzner cloud resources managed via Terraform in `terraform/`.
