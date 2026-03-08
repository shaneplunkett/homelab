# Cube

## Summary

Secondary Proxmox host. Runs critical always-on services (Plex, media automation) that need to stay stable and unaffected by experiments on PVE.

- **CPU:** Intel (12 threads, UHD 630 iGPU for Plex transcoding)
- **RAM:** 32 GB
- **Storage:** 1 TB NVMe (local-lvm thin pool) + 1 TB NVMe (unmounted, second drive)
- **IP:** 192.168.1.238

## Proxmox Storage Pools

Unraid NFS shares managed by Proxmox (mounted at `/mnt/pve/<name>/`, options: `soft,nofail`):

| Storage ID       | Unraid Export          | Purpose               |
|------------------|------------------------|-----------------------|
| unraid-media     | `/mnt/user/Media`      | Media library         |
| unraid-appdata   | `/mnt/user/appdata`    | App config data       |
| unraid-programs  | `/mnt/user/Programs`   | Programs/software     |

Proxmox handles mount lifecycle, reconnection, and health — visible in the web UI under Storage.

## Resources

| ID  | Type | Name | IP            | Purpose                                      |
|-----|------|------|---------------|----------------------------------------------|
| 103 | LXC  | arr  | 192.168.1.90  | Media automation (*arr stack, downloads, Overseerr) |
| 104 | LXC  | plex | 192.168.1.237 | Plex Media Server (iGPU hardware transcoding) |
