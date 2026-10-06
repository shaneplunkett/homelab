# Plex LXC

## Summary

Ubuntu LXC running Plex Media Server with the host's Intel iGPU passed through for QuickSync transcoding. Container is defined in `terraform/cube-plex.tf`.

## iGPU Passthrough

**Not in Terraform, set by hand on the host.** `terraform/cube-plex.tf` doesn't declare these, so this section is their only record. If the container is ever recreated, add them back to `/etc/pve/lxc/<ctid>.conf` on cube:

```
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
```

- `c 226:0` allows `/dev/dri/card0`
- `c 226:128` allows `/dev/dri/renderD128` (the render node Plex actually uses)
- The mount entry bind-mounts `/dev/dri` into the container

## Notes

- Plex runs natively (`plexmediaserver.service`), not in Docker. That keeps iGPU access simple: no extra device plumbing through a container runtime.
- Media comes from the `unraid-media` Proxmox storage pool, bind-mounted in the same way as the arr LXC.
- The Plex port-forward on the router is the only thing in the homelab exposed directly to the WAN.
