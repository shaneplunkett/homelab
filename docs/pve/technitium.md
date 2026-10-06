# Technitium DNS

Technitium does recursion, ad blocking and real authoritative zones in one
service, and it has built-in clustering. Pi-hole or AdGuard would each have
needed extra pieces to cover the same ground.

## What it does here

- It's the resolver for the LAN and the tailnet, with ad blocking and a local
  `shaneplunkett.com` zone. That zone is the LAN side of the split view, and
  its wildcard points at the nginx ingress host (`modules/services/nginx-ingress`).
- There are two clustered nodes on separate Proxmox hosts: the primary on pve
  (`stacks/pve/technitium-lxc`) and the secondary on cube
  (`stacks/cube/technitium2-lxc`). DHCP and the tailnet both hand out both
  nodes, so either one can keep DNS up alone.
- Zone records point at LAN addresses only. Remote clients reach them through
  a Tailscale subnet route for the LAN, so there's one zone with one set of
  answers and no Split Horizon app.
- MagicDNS can't serve an owned domain. That's why Technitium is the tailnet's
  global nameserver (with Override on), and MagicDNS stays on for `ts.net`
  names.

## Upgrade runbook (lock-step)

Every node in the cluster has to run the same release. Some major versions
have broken cluster compatibility.

1. Read the changelog. Technitium's docs are scattered, so the changelog and
   the blog posts are the real manual.
2. Export a config backup zip from the primary's console.
3. Bump the pinned image tag in both compose files in the same change.
4. Recreate the primary, then the secondary straight after, in the same
   maintenance window.
5. A one-off restart may be needed afterwards (see the memory notes below).

## Clustering gotchas

- Zones don't sync by default. A new zone has to be added to the cluster
  catalog zone (zone options → catalog) before the secondary serves it.
  Settings, blocklists, users and DNS apps sync on their own.
- Cluster init renames each node's server domain into the cluster domain. The
  bare hostname then returns NXDOMAIN, so healthchecks have to dig the node's
  FQDN.
- Cluster init also turns on the TLS web service on 53443 for node-to-node
  sync, so the compose files have to publish that port.
- Node-to-node TLS uses DANE-EE, so a clustered console can't sit behind an
  HTTPS reverse proxy. Only a TCP proxy works.
- DHCP scopes and per-node cache and logs don't sync.
- The secondary has no backup of its own. To rebuild it, deploy a fresh
  container and re-join it to the primary (`/api/admin/cluster/initJoin`).
  The join needs ignore-cert-errors, because the cluster domain doesn't
  resolve publicly.

## Runtime gotchas

- Docker only marks the container unhealthy and never restarts it. A cron job
  on each node runs `autoheal.sh` (in each stack dir) to do the restart.
- .NET memory grows over time, especially after upgrades, and the upstream
  root cause is still open. Blocklists live fully in RAM, and during the daily
  update the old and new lists are both loaded, so peak memory is roughly
  double. Size the LXCs with that peak in mind.
- `DNS_SERVER_*` env vars only apply on first start. After that the config in
  the volume wins, so changing compose won't change a running server's
  settings.

## Tailscale lessons

- Only use `--accept-routes` on devices that live off the LAN. On a LAN
  machine it hairpins local traffic through the subnet router. MTU-sensitive
  UDP fails first, and asymmetric routing once black-holed a node's LAN TCP
  entirely. `terraform/modules/tailscale-lan` enforces this on LXCs at boot.
  Macs and iPhones accept routes automatically, so if their LAN transfers are
  slow, check this first.
- The subnet router host needs `net.ipv4.ip_forward=1`, persisted.
- The DNS nodes run `--accept-dns=false`. Otherwise Proxmox and Tailscale
  point their resolv.conf at Tailscale DNS, which loops back to themselves.
- A split-DNS entry for a domain beats the global nameserver. A stale
  `shaneplunkett.com` split-DNS entry once overrode Technitium for that
  domain, so remove those entries rather than leaving them behind.

## Local zone shadows Cloudflare

The local `shaneplunkett.com` zone is a full primary zone, so on the LAN it
answers for the whole domain. A record that exists only in Cloudflare (for
example a CNAME to a Pages site) returns NXDOMAIN locally until it's mirrored
into the local zone. TXT and mail records don't need mirroring, because
external mail servers never ask this resolver.

## Backups

`stacks/pve/technitium-lxc/backup.sh` runs restic on the primary. It exports
the config zip through the API and copies the raw config volume, minus the
query-log database. Restore takes zips from older versions too. The primary's
backup is the source of truth for the whole cluster.
