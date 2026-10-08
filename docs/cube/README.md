# Cube

## Summary

Secondary Proxmox host. Runs critical always-on services (Plex, media automation) that need to stay stable and unaffected by experiments on PVE.

Per-service docs:

- [arr.md](arr.md)
- [plex.md](plex.md)

## Unraid storage

Unraid's NFS shares are Proxmox storage pools (`terraform/storage.tf`), so Proxmox owns the mount lifecycle, reconnection, and health. You can see them in the web UI under Storage.

LXCs don't mount NFS themselves. They bind-mount the host path `/mnt/pve/<storage id>` instead.

## Gotchas

- **The Media share can come up empty after Cube reboots.** The kernel
  rejects it at boot with `NFS: server 192.168.1.132 error: fileid changed`
  in `dmesg`, Proxmox shows `unraid-media` as inactive, and Plex and arr see
  an empty `/mnt/media`. The other shares mount fine. It happened on the
  first boot into kernel 7.0. A remount fixes it, then the containers need a
  restart to pick up the new mount:

  ```sh
  ssh shane@<cube> 'sudo umount -l /mnt/pve/unraid-media && sudo pvesm status'
  ssh shane@<cube> 'sudo pct reboot 102 && sudo pct reboot 104'
  ```
