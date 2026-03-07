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

Compose file at `/root/docker-compose.yaml`:

```yaml
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

**Deploy:**
```bash
cd /root
docker compose up -d
```
