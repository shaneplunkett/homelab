# Proxmox nodes

Config that lives on the Proxmox hosts themselves, outside Terraform and Nix.

## TUN for containers

`90-homelab-tun.conf` gives every container on a node `/dev/net/tun`, so
Tailscale can run in kernel mode. Every container includes
`common.conf.d` through `common.conf`, so there's nothing per-container.

Install it on each node, and again after rebuilding one:

```sh
scp proxmox/90-homelab-tun.conf root@<node>:/usr/share/lxc/config/common.conf.d/
```

Running containers only pick it up when they restart.

Why it's done this way:

- Proxmox only lets `root@pam` set device passthrough. API tokens are refused,
  even root's, so Terraform's token can't add `dev0` and CI never could.
- A container with both `dev0: /dev/net/tun` and this drop-in fails to start.
  PVE's autodev hook creates the device for `dev0` and dies when the bind
  mount already made it. Don't add `dev0` for TUN anywhere.
- No package owns the file, so Proxmox upgrades leave it alone.
