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
| 107 | LXC  | uptime-kuma  | 192.168.1.55 (DHCP) | Uptime Kuma monitoring                 |
| 108 | LXC  | dockhand     | 192.168.1.158 (DHCP) | Dockhand Docker management UI         |
| 109 | LXC  | technitium   | 192.168.1.5     | Technitium DNS (resolver, ad blocking)     |

Table verified against `pct list` / `qm list` 2026-09-04. The Palworld LXC
(106) was retired and destroyed after the completed hard-mode run; its final
archives are documented in `docs/pve/palworld.md`. The macos-tahoe VM
(previously 106) no longer exists; `docs/pve/macos-tahoe.md` is kept for
reference. An out-of-band, empty gitea LXC (110) was destroyed on 2026-08-21 —
it had proxy's MAC copy-pasted (from the since-removed gitea Terraform),
which had both containers fighting over 192.168.1.176 via DHCP.
