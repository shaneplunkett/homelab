# Cube

## Summary

Secondary Proxmox host. Runs critical always-on services (Plex, media automation) that need to stay stable and unaffected by experiments on PVE.

- **CPU:** Intel (12 threads, UHD 630 iGPU for Plex transcoding)
- **RAM:** 32 GB
- **Storage:** 1 TB NVMe (local-lvm thin pool) + 1 TB NVMe (unmounted, second drive)
- **IP:** 192.168.1.238

## Resources

| ID  | Type | Name | IP            | Purpose                                      |
|-----|------|------|---------------|----------------------------------------------|
| 103 | LXC  | arr  | 192.168.1.90  | Media automation (*arr stack, downloads, Overseerr) |
| 104 | LXC  | plex | 192.168.1.237 | Plex Media Server (iGPU hardware transcoding) |
