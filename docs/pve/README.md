# PVE

## Summary

Primary Proxmox host.

- **CPU:** Ryzen 9 7900 (12 cores / 24 threads)
- **RAM:** 96 GB
- **Storage:** 1 TB NVMe (local-lvm thin pool)
- **IP:** 192.168.1.169

## Resources

| ID  | Type | Name         | IP              | Purpose                                    |
|-----|------|--------------|-----------------|--------------------------------------------|
| 100 | VM   | Unraid       | —               | NAS, media storage (USB boot, PCIe HBA+NVMe) |
| 101 | LXC  | proxy        | 192.168.1.176   | Nginx Proxy Manager (reverse proxy, SSL)   |
| 105 | LXC  | mcphub       | 192.168.1.195   | MCPHub, Graphiti, Open Wearables           |
| 106 | LXC  | palworld     | 192.168.1.96 (DHCP, pinned MAC) | Palworld dedicated server  |
| 107 | LXC  | uptime-kuma  | 192.168.1.55 (DHCP) | Uptime Kuma monitoring                 |
| 108 | LXC  | dockhand     | 192.168.1.158 (DHCP) | Dockhand Docker management UI         |
| 109 | LXC  | technitium   | 192.168.1.5     | Technitium DNS (resolver, ad blocking)     |
| 110 | LXC  | gitea        | 192.168.1.189 (DHCP) | Gitea — **not in terraform** (created out-of-band) |

Table verified against `pct list` / `qm list` 2026-08-21. The macos-tahoe VM
(previously 106) no longer exists; `docs/pve/macos-tahoe.md` kept for
reference. Gitea's MAC was regenerated 2026-08-21 — it was a duplicate of
proxy's (copy-paste in the since-removed gitea terraform), which had both
containers fighting over 192.168.1.176 via DHCP.
