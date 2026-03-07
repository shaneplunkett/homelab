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
| 106 | VM   | macos-tahoe  | 192.168.1.205   | macOS Tahoe — Apple MCP servers for Vex    |
