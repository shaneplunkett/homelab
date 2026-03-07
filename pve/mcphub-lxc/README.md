# MCPHub LXC

## Summary

Alpine LXC container on PVE running the MCP infrastructure stack and Open Wearables platform.

- **CTID:** 105
- **Hostname:** mcphub
- **IP:** 192.168.1.195
- **OS:** Alpine 3.22.3
- **Cores:** 4
- **RAM:** 6 GB
- **Swap:** 2 GB
- **Disk:** 32 GB (local-lvm)
- **Tailscale:** Configured for remote access
- **Boot on start:** yes

## Proxmox Config

`/etc/pve/lxc/105.conf`:

```
arch: amd64
cores: 4
features: nesting=1,keyctl=1
hostname: mcphub
memory: 6144
net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:83:6C:69,ip=dhcp,type=veth
onboot: 1
ostype: alpine
rootfs: local-lvm:vm-105-disk-0,size=32G
swap: 2048
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
lxc.apparmor.profile: unconfined
lxc.mount.auto: proc:rw sys:rw cgroup:rw
lxc.cap.drop:
```

Key config notes:
- `nesting=1,keyctl=1` — required for Docker-in-LXC
- `onboot: 1` — starts automatically with the Proxmox host
- `lxc.mount.entry: /dev/net/tun` — TUN device for Tailscale
- `lxc.apparmor.profile: unconfined` + `lxc.cap.drop:` (empty) — full capabilities for Docker and Tailscale
- `lxc.cgroup2.devices.allow: c 10:200 rwm` — allows `/dev/net/tun` device access

## Stacks

### mcphub/

The core MCP infrastructure — MCPHub, Graphiti knowledge graph, Neo4j, pgvector. This is the brain that powers Vex across Claude Code and Claude Desktop.

**Services:**
- **MCPHub** — MCP server aggregator with smart routing (port 3000)
- **Graphiti MCP** — episodic knowledge graph server (custom image)
- **Neo4j 5.26** — graph database backing Graphiti
- **PostgreSQL 17** (pgvector) — vector storage for MCPHub

**Deploy:**
```bash
cd /opt/mcphub
docker compose up -d
```

### open-wearables/

Health data platform — forked from [the-momentum/open-wearables](https://github.com/the-momentum/open-wearables) with custom cardiac service, timeseries tools, and MCP server.

**Repo:** [shaneplunkett/open-wearables](https://github.com/shaneplunkett/open-wearables)

**Services:**
- **FastAPI backend** (port 8001)
- **React frontend** (port 3001)
- **MCP server** — FastMCP 2.0 (port 8002), wired into MCPHub
- **PostgreSQL 18** (port 5433)
- **Redis 8** (port 6380)
- **Celery** worker + beat
- **Flower** — Celery monitoring (port 5556)

**Deploy:**
```bash
cd /opt/open-wearables
git pull
docker compose up -d --build
```
