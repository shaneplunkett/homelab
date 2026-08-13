# Proxy LXC

## Summary

Alpine LXC running Nginx Proxy Manager for reverse proxying and SSL termination across the homelab.

- **CTID:** 101
- **Hostname:** proxy
- **IP:** 192.168.1.176
- **OS:** Alpine 3.22.3
- **Cores:** 2
- **RAM:** 1 GB
- **Swap:** 512 MB
- **Disk:** 8 GB (local-lvm)

## Proxmox Config

`/etc/pve/lxc/101.conf`:

```
arch: amd64
cores: 2
features: nesting=1
hostname: proxy
memory: 1024
net0: name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:65:53:9F,ip=dhcp,type=veth
ostype: alpine
rootfs: local-lvm:vm-101-disk-0,size=8G
swap: 512
unprivileged: 1
```

Note: `nesting=1` is required for Docker-in-LXC.

## Services

### Nginx Proxy Manager

- **Admin UI:** http://192.168.1.176:81
- **HTTP:** port 80
- **HTTPS:** port 443
- **Image:** `jc21/nginx-proxy-manager:latest`

Compose file is repo-managed at `stacks/pve/proxy-lxc/npm/docker-compose.yml`.
Data lives on the LXC under `/var/lib/containers/npm/`:

- `/var/lib/containers/npm/data` → `/data` (NPM config, generated nginx configs)
- `/var/lib/containers/npm/letsencrypt` → `/etc/letsencrypt` (certs; wildcard
  `*.shaneplunkett.com` + `*.shaneplunkett.dev` renewed via Cloudflare DNS-01)

**Deploy:**
```bash
docker compose up -d
```

## DNS

Internal `*.shaneplunkett.com` names resolve to this LXC via a wildcard record
in Technitium DNS (192.168.1.5) — see `docs/pve/technitium-research.md`. New
services need only an NPM proxy-host entry; no DNS change required.
