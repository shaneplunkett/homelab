# Plex LXC

## Summary

Ubuntu LXC running Plex Media Server with Intel iGPU passthrough for hardware transcoding.

- **CTID:** 104
- **Hostname:** plex
- **IP:** 192.168.1.237 (DHCP)
- **OS:** Ubuntu
- **Cores:** 4
- **RAM:** 8 GB
- **Swap:** 1 GB
- **Disk:** 150 GB (local-lvm)

## Proxmox Config

`/etc/pve/lxc/104.conf`:

```
arch: amd64
cores: 4
features: nesting=1
hostname: plex
memory: 8192
mp0: /mnt/pve/unraid-media,mp=/mnt/media
net0: name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:AA:D1:7C,ip=dhcp,type=veth
ostype: ubuntu
rootfs: local-lvm:vm-104-disk-0,size=150G
swap: 1024
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
```

Key config notes:
- **iGPU passthrough** for hardware transcoding:
  - `c 226:0` — `/dev/dri/card0`
  - `c 226:128` — `/dev/dri/renderD128`
  - `/dev/dri` bind-mounted into the container
- Media via Proxmox-managed NFS storage pool (`unraid-media`), bind-mounted at `/mnt/media`
- `nesting=1` — standard LXC feature
- Plex is installed natively (systemd service), not Docker

## Service

- **Plex Media Server** — `plexmediaserver.service`
- **GPU:** Intel UHD 630 (CoffeeLake-S) for QuickSync transcoding

## Notes

- Plex runs as a native systemd service, not Docker — this simplifies iGPU access
- 150 GB disk accommodates Plex metadata, thumbnails, and transcoding cache
- Media accessed via Proxmox-managed NFS storage pool bind mount (same pattern as arr LXC)
