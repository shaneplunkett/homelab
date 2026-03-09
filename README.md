# Homelab

## Summary

Documentation of homelab infrastructure, including docker compose configs, Proxmox VM/LXC configs, and setup guides.

## Hosts

| Host | IP            | Hardware                          | Purpose                     |
|------|---------------|-----------------------------------|-----------------------------|
| PVE  | 192.168.1.169 | Ryzen 9 7900, 96 GB RAM, 1 TB NVMe | Primary Proxmox node       |
| Cube | 192.168.1.238 | Intel (UHD 630), 32 GB RAM, 2x 1 TB NVMe | Secondary Proxmox node |
| hetzvps | REDACTED_IP | Hetzner cax11 (2 vCPU ARM, 4 GB RAM) | Tailscale exit node (NixOS) |

## Network Map

Managed by Unifi. Static IPs / DHCP reservations:

| IP              | Name          | Type | Host    | Purpose                                    |
|-----------------|---------------|------|---------|--------------------------------------------|
| 192.168.1.90    | arr           | LXC  | Cube    | Media automation (*arr stack, Overseerr)   |
| 192.168.1.169   | PVE           | Host | —       | Primary Proxmox host                      |
| 192.168.1.176   | proxy         | LXC  | PVE     | Nginx Proxy Manager                       |
| 192.168.1.195   | mcphub        | LXC  | PVE     | MCPHub, Graphiti, Open Wearables           |
| 192.168.1.205   | macos-tahoe   | VM   | PVE     | macOS Tahoe — Apple MCP servers            |
| 192.168.1.237   | plex          | LXC  | Cube    | Plex Media Server (iGPU transcoding)      |
| 192.168.1.238   | Cube          | Host | —       | Secondary Proxmox host                    |
| REDACTED_IP    | hetzvps       | VPS  | Hetzner | Tailscale exit node (NixOS)               |

## Backups

MCPHub data backed up every 4 hours via restic to a Hetzner Storage Box in Helsinki. See [docs/hetzner/backups.md](docs/hetzner/backups.md).

## Structure

Folder per host, subfolders per resource on host. Each subfolder has a README and docker compose if relevant. Hetzner cloud resources managed via Terraform in `terraform/`.
