# Cube

## Summary

Secondary Proxmox host. Runs critical always-on services (Plex, media automation) that need to stay stable and unaffected by experiments on PVE.

Per-service docs:

- [arr.md](arr.md)
- [plex.md](plex.md)

## Unraid storage

Unraid's NFS shares are Proxmox storage pools (`terraform/storage.tf`), so Proxmox owns the mount lifecycle, reconnection, and health. You can see them in the web UI under Storage.

LXCs don't mount NFS themselves. They bind-mount the host path `/mnt/pve/<storage id>` instead.
