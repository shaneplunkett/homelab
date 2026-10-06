# MCPHub LXC

## Summary

Alpine LXC on PVE running the MCP infrastructure stack (the brain that powers Vex across Claude Code and Claude Desktop) and the Open Wearables platform. Declared in `terraform/pve-mcphub.tf`. Tailscale is installed by the `tailscale-lan` module and apk upgrades come from the `lxc-baseline` module.

## LXC config

These settings live in the container's Proxmox config, not in Terraform, so a rebuild has to set them again by hand:

- `nesting=1,keyctl=1`: required for Docker-in-LXC
- `lxc.mount.entry: /dev/net/tun` plus `lxc.cgroup2.devices.allow: c 10:200 rwm`: the TUN device Tailscale needs
- `lxc.apparmor.profile: unconfined` plus an empty `lxc.cap.drop:`: full capabilities for Docker and Tailscale

## Stacks

### mcphub/

The core MCP infrastructure, defined in `stacks/pve/mcphub-lxc/mcphub/` and deployed to `/opt/mcphub` with `docker compose up -d`.

Obsidian Sync needs a one-time interactive setup after the first deploy: run `ob login`, then `ob sync-setup`, inside the obsidian-sync container.

### open-wearables/

Health data platform, forked from [the-momentum/open-wearables](https://github.com/the-momentum/open-wearables). It lives in its own repo ([shaneplunkett/open-wearables](https://github.com/shaneplunkett/open-wearables)), not this one, and is deployed from a checkout:

```bash
cd /opt/open-wearables
git pull
docker compose up -d --build
```

## Backups

Backups run from `stacks/pve/mcphub-lxc/backup.sh`. See [docs/hetzner](../hetzner/README.md).
