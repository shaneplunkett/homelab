# Technitium DNS Server — homelab deployment evaluation

**Research date:** 2026-08-13
**Version evaluated:** v15.4 (released 11 July 2026)
**Scope:** desk research against primary sources only (official site, GitHub
repo/changelog, Docker Hub, author's blog, and the competing projects' own
docs). No test deployment was made.

> **As built (2026-08-13):** deployed same day. LXC 109 `technitium` at
> 192.168.1.5 (tailnet: 100.98.28.127, `tag:infra`), image pinned `15.4.0`,
> compose at `/opt/technitium`, admin password in Bitwarden
> (`technitium-dns`). Primary zone `shaneplunkett.com` with wildcard →
> 192.168.1.176 + `redbook` CNAME; stale `auth`/`mcp-memory`/`pihole`
> dropped. Blocklists: StevenBlack + OISD big (~180 MiB resident).
> LAN DHCP DNS and Tailscale global nameserver (Override on) both point at
> it; MagicDNS retained. Deltas from plan: a pre-existing Tailscale split
> DNS entry `shaneplunkett.com → 192.168.1.1` had to be deleted (it beat
> the global nameserver and would have broken tailnet resolution once the
> Unifi records were removed), and `net.ipv4.ip_forward` needed enabling on
> pve for the subnet route. The 16 Unifi static A records and 4 dead
> Cloudflare CNAMEs (`collabora`, `kimai`, `nextcloud`, `overseerr`) are
> deleted. Daily restic backup to the Hetzner storage box via
> `stacks/pve/technitium-lxc/backup.sh`. Remaining: SHA-56 (second
> clustered instance).

## TL;DR

- Technitium DNS Server is a **GPLv3, cross-platform C#/.NET DNS server** that
  is authoritative resolver, recursive resolver, ad-blocker, and DHCP server
  in a single binary with a web console and full HTTP API. It replaces the
  usual Pi-hole + Unbound (+ separate DHCP) stack with one service.
  [README](https://github.com/TechnitiumSoftware/DnsServer)
- Actively maintained: v15.4 shipped 11 July 2026, with releases roughly
  every one to two months and a major version about yearly.
  [CHANGELOG](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)
  It is effectively a **single-maintainer project** (Shreyas Zare authored
  ~98% of commits), which is the main structural risk.
- Deployment fits this repo's pattern: official Docker image
  (`technitium/dns-server`, ~106 MB) with a maintained compose example, or a
  bare install in an LXC via the official `install.sh` (Debian/Ubuntu
  systemd, and Alpine/OpenRC since v15.3).
- Standout wins over Pi-hole/AdGuard Home: built-in recursion (no upstream
  trust required), proper authoritative zones (primary/secondary/catalog,
  DNSSEC signing, RFC 2136), DoH/DoT/DoQ both as server and forwarder, and
  config-sync clustering for a two-node HA-ish setup.
- Main gotchas: .NET memory footprint is larger than dnsmasq/Unbound and
  there are recurring (unresolved) memory-growth reports after upgrades;
  DHCP requires host networking in Docker; port 53 clashes with
  systemd-resolved on stock Ubuntu; docs are scattered across blog posts and
  a help page last updated in 2021.

## 1. What it is

Technitium DNS Server is "an open source authoritative as well as recursive
DNS server" with a web console, written as a cross-platform .NET application
(currently .NET 10) running on Windows, Linux, macOS, and Raspberry Pi
(arm7+). [README](https://github.com/TechnitiumSoftware/DnsServer)

- **Licence:** GPL-3.0
  ([LICENSE](https://github.com/TechnitiumSoftware/DnsServer/blob/master/LICENSE),
  confirmed via the GitHub API SPDX id `GPL-3.0`).
- **Maintainer:** Shreyas Zare (Technitium, Mumbai). The GitHub contributor
  stats show 4,004 of roughly 4,090 commits are his; the next contributor has
  42. Sponsorship logos on the README and Patreon fund development. Treat it
  as a single-maintainer project with occasional community PRs (dark mode,
  Alpine support, PostgreSQL query logs and Unix-socket support all came in
  as PRs per the
  [changelog](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
- **Maturity:** first released November 2017
  ([launch post](https://blog.technitium.com/2017/11/technitium-dns-server-released.html));
  repo created 2017-10-29, ~9,500 GitHub stars, ~160 open issues as of this
  research (GitHub API).
- **Release cadence (from the
  [changelog](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)):**
  v14.3 (20 Dec 2025), v15.0 (25 Apr 2026, .NET 10 upgrade + SSO + non-root
  service install), v15.1 (3 May 2026), v15.2 (9 May 2026), v15.3 (5 Jul
  2026), v15.4 (11 Jul 2026). Majors land roughly yearly (v13 Sep 2024, v14
  Nov 2025, v15 Apr 2026).
- Security posture looks healthy for a small project: v15.x releases credit
  external researchers (Tsinghua University, Palo Alto Networks, Tenzai) for
  reported amplification, privilege-escalation, and XSS issues, all fixed in
  the release they were disclosed in
  ([changelog v15.0/v15.3](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).

## 2. Feature inventory (homelab-relevant)

### Authoritative + recursive in one

The server does full recursive resolution from the roots itself — QNAME
minimisation (RFC 9156), QNAME case randomisation, latency-based name-server
selection, serve-stale, prefetching, and persistent on-disk cache across
restarts are all built in
([README](https://github.com/TechnitiumSoftware/DnsServer)). This is the key
architectural difference from Pi-hole: Pi-hole's own docs describe FTLDNS as
"a caching and *forwarding* DNS server" that hands every miss to a configured
external upstream, and their recommended fix for that trust problem is to
install and pair Unbound alongside it
([Pi-hole unbound guide](https://docs.pi-hole.net/guides/dns/unbound/)).
Technitium collapses that two-service setup into one, and can still be run in
forwarder mode instead (recursion is a setting: `Allow`, `Deny`,
`AllowOnlyForPrivateNetworks` — the default — or a custom ACL, per the
[compose example](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)).

### Ad/tracker blocking

- One or more blocklist URLs feed a "Block List Zone"; lists are re-fetched
  **every 24 hours automatically**
  ([official help](https://technitium.com/dns/help.html)). Allowed Zones
  provide exceptions; blocked names answer `0.0.0.0`/`::`.
- CNAME cloaking (block domains whose CNAME target is blocked) is built in
  ([README](https://github.com/TechnitiumSoftware/DnsServer)).
- The **Advanced Blocking DNS App** adds regex lists, different lists per
  client IP/subnet group, a configurable blocking-answer TTL, and a blocklist
  update interval configurable in minutes rather than the fixed 24 h
  ([README](https://github.com/TechnitiumSoftware/DnsServer),
  [changelog v14.3](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
- The help page does not name specific list formats; the standard hosts-file
  and domain-list formats used by common blocklists are what the feature is
  built around, but I could not verify an explicit format list in a primary
  source, and AdBlock-syntax support is only documented for the Advanced
  Blocking app's regex mode. Flagging that as unverified.

### Built-in DHCP server

- Multiple scopes, works across networks and with relay agents. With the
  domain-name option set, the DHCP server **automatically registers forward
  and reverse DNS records for every lease** — the DHCP→DNS dynamic
  registration Pi-hole/AdGuard users usually want
  ([official help](https://technitium.com/dns/help.html)).
- Reserved leases keep persistent DNS records even when not allocated, and
  dynamic leases can be allowed to overwrite existing A records
  ([changelog v15.0, v14.3](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
- Limits: no DHCPv6 yet, and DHCP scopes are **not** synced by the clustering
  feature (both planned for a later major release, per the
  [clustering post](https://blog.technitium.com/2025/11/understanding-clustering-and-how-to.html)).

### Encrypted DNS

- **As a server:** self-host DNS-over-TLS, DNS-over-HTTPS (HTTP/1.1, /2 and
  /3), and DNS-over-QUIC; plus plain DNS-over-HTTP on 80/8053 for use behind
  a TLS-terminating reverse proxy, and PROXY protocol v1/v2 support
  ([README](https://github.com/TechnitiumSoftware/DnsServer),
  [compose example](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)).
  Setup guides: [DoH/DoT](https://blog.technitium.com/2020/07/how-to-host-your-own-dns-over-https-and.html)
  and [DoQ/HTTP-3](https://blog.technitium.com/2023/02/configuring-dns-over-quic-and-https3.html).
- **As a client/forwarder:** upstreams can be reached over UDP, TCP, TLS,
  HTTPS, or QUIC ([README](https://github.com/TechnitiumSoftware/DnsServer);
  the Docker env var `DNS_SERVER_FORWARDER_PROTOCOL` lists
  `Udp, Tcp, Tls, Https, HttpsJson`).
- **DNSCrypt is not supported in either direction and there is no plan to
  implement it** — the maintainer's suggested workaround is running
  dnscrypt-proxy as a forwarder
  ([issue #1096](https://github.com/TechnitiumSoftware/DnsServer/issues/1096)).

### DNSSEC

- Validation with RSA, ECDSA and EdDSA (NSEC and NSEC3) for the recursive
  resolver, forwarders, and conditional forwarders, over every supported
  transport ([README](https://github.com/TechnitiumSoftware/DnsServer)).
- **Signing** of hosted zones with the same algorithm set — something neither
  Pi-hole nor AdGuard Home offers at all
  ([README](https://github.com/TechnitiumSoftware/DnsServer),
  [signing guide](https://blog.technitium.com/2022/07/how-to-secure-your-domain-name-with-.html)).

### Zones

Primary, Secondary, Stub, and Conditional Forwarder zones; Catalog Zones
(RFC 9432) for auto-provisioning secondaries; AXFR/IXFR + NOTIFY; zone
transfer over TLS (RFC 9103) and QUIC; TSIG; ZONEMD validation; dynamic
updates (RFC 2136) with security policies; ANAME (CNAME-at-apex flattening);
record expiry/aging; per-record enable/disable
([README](https://github.com/TechnitiumSoftware/DnsServer),
[catalog zones guide](https://blog.technitium.com/2024/10/how-to-configure-catalog-zones-for.html)).
Split-horizon responses are handled by the Split Horizon DNS App rather than
view-style config ([README](https://github.com/TechnitiumSoftware/DnsServer)).

### DNS Apps (plugin ecosystem)

DNS Apps are server-side plugins, installable from a built-in app store, that
can intercept or answer queries ("just like web apps run on a web server")
([official help](https://technitium.com/dns/help.html),
[DNS Apps intro](https://blog.technitium.com/2021/03/creating-and-running-dns-apps-on.html)).
First-party apps in the
[repo's `Apps/` directory](https://github.com/TechnitiumSoftware/DnsServer/tree/master/Apps):
Advanced Blocking, Advanced Forwarding (bulk conditional forwarding), Auto
PTR, Block Page, Default Records, DNS64, DNSBL/RBL hosting, DNS Rebinding
Protection, Drop Requests, **Failover**, Filter AAAA, **Geo Continent / Geo
Country / Geo Distance** (with ASN support since v15), Log Exporter, No Data,
NX Domain, NX Domain Override, Query Logs backends (SQLite, MySQL,
PostgreSQL, SQL Server), **Split Horizon**, Weighted Round Robin, What Is My
DNS, Wild IP, and Zone Alias.

### Web console, API, logging, stats

- Web console (default TCP 5380, HTTPS on 53443) with dark mode, multi-user
  role-based access, TOTP 2FA, and SSO via OpenID Connect since v15
  ([README](https://github.com/TechnitiumSoftware/DnsServer)).
- Everything the console does goes through the documented **HTTP API**
  ([APIDOCS.md](https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md)),
  with non-expiring API tokens and, since v15, `Authorization: Bearer`
  headers, a **Prometheus metrics endpoint**, and a query-log-free
  health-check endpoint (`/api/dnsClient/healthCheck`)
  ([changelog v15.0/v15.3](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
- Dashboard stats over last hour/day/week/month/year; query logs viewable in
  the console with a live-update mode, or shipped to SQL backends via the
  Query Logs apps ([official help](https://technitium.com/dns/help.html),
  [changelog v15.0](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).

### Clustering / HA

Built-in since v14: one primary node plus secondaries, syncing settings,
users/groups/permissions, allowed/blocked lists, and DNS apps, with a
notification mechanism and the option to promote a secondary if the primary
dies. Zones sync via a special cluster catalog zone (including DNSSEC private
keys). Caveats: DHCP scopes and per-node cache/logs are **not** synced,
node-to-node TLS uses DANE-EE so you cannot put an HTTPS reverse proxy in
front of the web service of clustered nodes (TCP proxy only), and cluster
nodes must all run the same release across upgrades (breaking changes in
v14.2 and v15.0)
([clustering deep-dive](https://blog.technitium.com/2025/11/understanding-clustering-and-how-to.html),
[changelog](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
Note this is config-sync management, not anycast/VRRP failover — client-side
redundancy still comes from handing out two DNS server IPs via DHCP.

## 3. Deployment options on PVE

### Official Docker image

- `technitium/dns-server` on
  [Docker Hub](https://hub.docker.com/r/technitium/dns-server): "Sponsored
  OSS", 10 M+ pulls, `latest` image ~106 MB. Tags are `latest` plus pinned
  semver (`15.4.0`, `15.3.0`, … back through `13.x`), so version pinning
  works (Docker Hub tags API).
- The maintained
  [docker-compose.yml](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)
  maps: `5380/tcp` web console (`53443/tcp` HTTPS), `53/udp+tcp` DNS,
  optional `853/udp` DoQ, `853/tcp` DoT, `443/udp+tcp` DoH, `80`/`8053` DoH
  behind a proxy, and `67/udp` DHCP.
- **DHCP requires `network_mode: "host"`** — the compose file's own comment
  says to switch to host mode and drop all port mappings for DHCP
  deployments (DHCP broadcast traffic doesn't survive Docker's bridge NAT).
- Bridge mode ships a
  `net.ipv4.ip_local_port_range=1024 65535` sysctl (removed for host mode) so
  the recursive resolver has enough ephemeral source ports.
- Volumes: `/etc/dns` (all config/state) and `/var/log/technitium/dns`.
- First-boot config via `DNS_SERVER_*` environment variables (admin password,
  forwarders, recursion ACL, blocklists, log/stat retention, etc.) —
  [DockerEnvironmentVariables.md](https://github.com/TechnitiumSoftware/DnsServer/blob/master/DockerEnvironmentVariables.md).
  These only initialise settings on first start; after that the config on the
  volume wins.

### Direct install in an LXC (Debian/Ubuntu/Alpine)

It's a .NET app, so the
[official Linux install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)
offers:

- **Automated:** `curl -sSL https://download.technitium.com/dns/install.sh | sudo bash`
  — installs the ASP.NET Core runtime and the DNS server, and since v15
  registers a hardened **non-root systemd service**
  ([changelog v15.0](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
  A matching `uninstall.sh` removes both. **Alpine Linux with OpenRC is
  supported by the installer since v15.3**
  ([changelog](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)),
  which matters here since this repo's LXCs are Alpine.
- **Manual:** install the ASP.NET Core 10 runtime from Microsoft's package
  repos, then untar `DnsServerPortable.tar.gz` into `/opt/technitium/dns` and
  install the bundled systemd unit
  ([install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)).
- Raspberry Pi arm7 upward is supported (arm6 Pi 1/Zero are not), so any x86
  PVE LXC is comfortably in range
  ([install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)).

### Resource requirements

No official minimum RAM/CPU figure is published — flagging that explicitly.
Verifiable data points:

- The image is ~106 MB and the app targets Raspberry Pi-class hardware
  ([Docker Hub](https://hub.docker.com/r/technitium/dns-server),
  [install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)).
- The README's performance claim is >100,000 req/s on an i7-8700 — headroom
  is not a concern at homelab query rates
  ([README](https://github.com/TechnitiumSoftware/DnsServer)).
- Memory scales with blocklists: the maintainer states blocklists are fully
  loaded into memory at roughly **300 MB per million blocked domains, and
  double that transiently during list updates** (old + new lists coexist
  until swap-over)
  ([maintainer comment, issue #2030](https://github.com/TechnitiumSoftware/DnsServer/issues/2030)).
- The dashboard stats module and the SQLite query-logs app add further memory
  under load; "Enable In-Memory Stats" (also exposed as
  `DNS_SERVER_STATS_ENABLE_IN_MEMORY_STATS`) cuts stats memory significantly
  at the cost of only keeping the last hour
  ([issue #2030](https://github.com/TechnitiumSoftware/DnsServer/issues/2030),
  [compose example](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)).

Practical sizing for a container here: 1 vCPU and 512 MB runs a modest
blocklist set; 1 GB gives comfortable headroom for larger lists plus the
double-loading spike. (Sizing inference from the 300 MB/million figure above,
not an official recommendation.)

## 4. Comparison: Technitium vs Pi-hole vs AdGuard Home vs Unbound

Each claim below is against the project's own documentation.

| Capability | Technitium | Pi-hole | AdGuard Home | Unbound |
| --- | --- | --- | --- | --- |
| Recursive resolution (from roots) | Built in, with QNAME minimisation, serve-stale, persistent cache ([README](https://github.com/TechnitiumSoftware/DnsServer)) | No — FTLDNS is "a caching and *forwarding* DNS server"; official guide pairs it with Unbound for recursion ([Pi-hole docs](https://docs.pi-hole.net/guides/dns/unbound/)) | No — forwards to configured upstreams (its README describes a sinkholing DNS server, not a recursive resolver) ([AGH README](https://github.com/AdguardTeam/AdGuardHome)) | Yes — "a validating, recursive, caching DNS resolver ... fast and lean" ([Unbound docs](https://unbound.docs.nlnetlabs.nl/en/latest/)) |
| Ad/tracker blocking | Blocklist URLs + Advanced Blocking app (regex, per-client groups) ([README](https://github.com/TechnitiumSoftware/DnsServer)) | Core feature, mature list ecosystem ([Pi-hole docs](https://docs.pi-hole.net/)) | Core feature, plus safe search, parental control, per-client config out of the box ([AGH README](https://github.com/AdguardTeam/AdGuardHome)) | Not a blocker; local-zone/RPZ data filtering only, no list management ([Unbound docs, Filtering](https://unbound.docs.nlnetlabs.nl/en/latest/)) |
| DHCP server (+ DNS registration) | Built in, multi-scope, auto forward+reverse records; no DHCPv6 yet ([help](https://technitium.com/dns/help.html), [clustering post](https://blog.technitium.com/2025/11/understanding-clustering-and-how-to.html)) | Built into FTL (dnsmasq-based) ([FTLDNS docs](https://docs.pi-hole.net/ftldns/)) | Built in ([AGH README](https://github.com/AdguardTeam/AdGuardHome)) | None |
| Encrypted DNS, server-side | DoH (H1/H2/H3), DoT, DoQ; no DNSCrypt ([README](https://github.com/TechnitiumSoftware/DnsServer), [#1096](https://github.com/TechnitiumSoftware/DnsServer/issues/1096)) | Not native — "requires additional software" per AGH's comparison; Pi-hole docs offer no built-in DoH/DoT server | DoH/DoT server built in per its own feature table ([AGH README](https://github.com/AdguardTeam/AdGuardHome)) | DoT and DoH server support in config ([Unbound docs](https://unbound.docs.nlnetlabs.nl/en/latest/)) |
| Encrypted upstreams | DoT/DoH/DoQ forwarders ([README](https://github.com/TechnitiumSoftware/DnsServer)) | Not native ([AGH comparison table](https://github.com/AdguardTeam/AdGuardHome)) | DoH/DoT/DNSCrypt upstreams ([AGH README](https://github.com/AdguardTeam/AdGuardHome)) | DoT forwarding; recursion is the default mode |
| Authoritative zones | Full: primary/secondary/stub/conditional forwarder, catalog zones, DNSSEC signing, AXFR/IXFR, TSIG, RFC 2136 ([README](https://github.com/TechnitiumSoftware/DnsServer)) | Local DNS records/CNAMEs only | DNS rewrites only | Limited local/auth-zone data; NLnet Labs points authoritative use at NSD |
| HTTP API | Full-coverage documented API + Prometheus metrics ([APIDOCS.md](https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md)) | REST API in v6 ([Pi-hole API docs](https://docs.pi-hole.net/api/)) | REST API (OpenAPI spec) ([AGH README](https://github.com/AdguardTeam/AdGuardHome)) | Remote-control socket/CLI, no HTTP API |
| Web UI | Yes, with RBAC, 2FA, SSO ([README](https://github.com/TechnitiumSoftware/DnsServer)) | Yes | Yes | No |
| Runtime/footprint | .NET 10; ~106 MB image; RAM scales with blocklists (~300 MB/million domains) ([Docker Hub](https://hub.docker.com/r/technitium/dns-server), [#2030](https://github.com/TechnitiumSoftware/DnsServer/issues/2030)) | C/PHP on dnsmasq fork; very light | Single Go binary; light | C, "fast and lean" by design ([Unbound docs](https://unbound.docs.nlnetlabs.nl/en/latest/)) |

Fair-play notes: Pi-hole has the largest community, the most battle-tested
blocklist ecosystem, and the smallest resource footprint of the blocker
options. AdGuard Home is a single static Go binary with the slickest
out-of-the-box family-filtering features and per-client controls. Unbound
remains the lightest, most conservative pure resolver — Technitium's
recursion engine is far younger than Unbound's. Technitium wins when you want
the whole stack (recursion + blocking + DHCP + authoritative + encrypted
serving) in one managed service.

## 5. Maintenance and update story

- **Docker:** update by pulling a new image tag; pinned semver tags exist so
  you can pin and bump deliberately
  ([Docker Hub tags](https://hub.docker.com/r/technitium/dns-server/tags)).
  There is no in-container self-update.
- **Bare install:** the web console shows an update notification (with a link
  to per-release update instructions); updating is "exactly the same process
  you followed to install" — re-run `install.sh`, or re-extract the portable
  tarball over `/opt/technitium/dns`
  ([maintainer, v15 release post comments](https://blog.technitium.com/2026/04/technitium-dns-server-v15-released.html),
  [install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)).
  The update check can be disabled globally or per user
  ([changelog v15.3](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
- **Config backup/restore:** the Settings section exports a backup zip of the
  whole config; Restore accepts backup zips **from older versions** too
  ([changelog v14.3/v15.0](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
  The maintainer explicitly recommends exporting a backup before major
  upgrades ([changelog v15.0](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md)).
- **Where state lives:** in Docker, everything is under the `/etc/dns` volume
  (config, zones, apps, DNSSEC keys) with logs under
  `/var/log/technitium/dns`
  ([compose example](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml));
  bare installs keep a `config` folder inside the installation directory
  (`/opt/technitium/dns`)
  ([changelog v15.0](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md),
  [install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)).
  Back the config volume/folder up alongside the exported zip.

## 6. Gotchas and known issues

1. **Port 53 conflicts with systemd-resolved/dnsmasq.** On stock Ubuntu (and
   Debian with resolved enabled) the server logs
   `SocketException (98): Address already in use`; the official guide walks
   through disabling systemd-resolved and fixing `/etc/resolv.conf`
   ([install guide](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)).
   The repo's Alpine LXCs sidestep this entirely.
2. **DHCP in Docker needs host networking** — the compose file's own comments
   say so, and host mode also means removing the port mappings and the
   ephemeral-port sysctl
   ([compose example](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)).
3. **.NET memory behaviour.** Multiple open issues report memory growth,
   especially after upgrades and in recursor mode
   ([#2030 "Memory Leak"](https://github.com/TechnitiumSoftware/DnsServer/issues/2030),
   [#2093 OutOfMemoryException during recursion](https://github.com/TechnitiumSoftware/DnsServer/issues/2093)).
   The maintainer's own analysis in #2030: blocklists live fully in memory
   (~300 MB/million domains, doubled during updates), the legacy stats module
   and the SQLite query-logs app add more, and a suspected DNS-app native-DLL
   double-load after updates "should fix itself with restarting the DNS
   server once" — but the root cause of the upgrade-time reports is, in his
   words, "still not clear". Budget RAM generously and expect an occasional
   restart after upgrades. A tiny C resolver this is not.
4. **Documentation is scattered.** The
   [official help page](https://technitium.com/dns/help.html) is stamped
   "Updated on: 2 May, 2021"; current behaviour is documented across the
   changelog, blog posts, and GitHub markdown files. Expect to read release
   notes rather than a manual.
5. **Single-maintainer risk.** ~98% of commits are one person (GitHub
   contributor stats). Cadence has been reliable for eight-plus years and
   security reports get fixed promptly, but bus-factor is 1 and some
   long-tail issues (e.g. the memory reports above) stay open.
6. **Cluster upgrades are lock-step.** v14.2 and v15.0 both shipped breaking
   clustering changes requiring all nodes on the same release
   ([changelog](https://github.com/TechnitiumSoftware/DnsServer/blob/master/CHANGELOG.md));
   clustered web consoles also can't sit behind an HTTPS reverse proxy (TCP
   proxy only)
   ([clustering post](https://blog.technitium.com/2025/11/understanding-clustering-and-how-to.html)).
7. **First-boot admin credentials.** The console starts with an admin account
   whose password should be set immediately — in Docker, set
   `DNS_SERVER_ADMIN_PASSWORD` (or `_FILE`) at first start
   ([compose example](https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml)).
8. **No DNSCrypt** in either direction, by explicit maintainer decision
   ([#1096](https://github.com/TechnitiumSoftware/DnsServer/issues/1096)).

## 7. Recommendation for this homelab

- **Deployment shape: Docker inside a dedicated Alpine LXC**, matching the
  existing `stacks/pve/*-lxc` + `terraform/modules/alpine-lxc` pattern (as
  used by `uptime-kuma-lxc`). Give it a **static IP** rather than `ip =
  "dhcp"` — a DNS server must not depend on the thing it may later replace.
  1 vCPU / 1 GB / 8 GB disk is comfortable given the blocklist memory maths
  above. Pin the image to a semver tag (e.g. `15.4.0`) and bump via Dockhand
  or renovate-style PRs rather than tracking `latest`.
- Start with **bridge networking and DNS-only duties** (ports 5380 + 53).
  Leave DHCP with the current router initially; if DHCP moves to Technitium
  later, switch the compose file to `network_mode: "host"` per the official
  example — that's the documented path and another reason a dedicated LXC
  (where host mode is harmless) beats co-tenanting an existing stack.
- **Run two instances if the network should survive maintenance.** DNS is the
  one service whose absence makes everything look broken. A second, smaller
  instance (even on different hardware, e.g. alongside Unraid) with v14+
  clustering syncing settings/blocklists/apps, and both IPs handed out via
  DHCP, is the sensible shape — remembering cluster nodes must upgrade
  together and DHCP scopes don't sync
  ([clustering post](https://blog.technitium.com/2025/11/understanding-clustering-and-how-to.html)).
  A single instance is acceptable only if the router's DNS remains a fallback.
- **Migration:** there is no existing Pi-hole/AdGuard/Unbound config in this
  repo to import, so migration is just repointing DHCP option 6 at the new
  LXC's IP. Sequence: deploy → set admin password → set recursion to
  private-networks-only (the default) → add blocklists → create the LAN
  primary zone → test from one client → flip DHCP's DNS option → export a
  config backup zip and stash it with the repo's other backup artefacts.
- **Verdict:** worth deploying. It consolidates resolver, blocking,
  authoritative LAN zones, and (later) DHCP into one service with a proper
  API for automation, at the cost of a heavier runtime and a bus-factor of
  one. The open memory-growth issues are the thing to watch: pin versions,
  read the changelog before bumping, and keep the backup zip current.

## 8. Technitium vs Nginx Proxy Manager — who owns what

Technitium does **not** replace NPM: it never sits in the HTTP traffic path,
terminates TLS, or holds certificates. The two operate at different layers
and pair well. The division of labour for this homelab:

| Job | Today | After Technitium |
| --- | --- | --- |
| Name resolution for `*.shaneplunkett.com` on the LAN | Unifi gateway static DNS records (16 A records) | Technitium local zone |
| Ad blocking + recursive resolution | Router / upstream DNS | Technitium |
| DHCP | Unifi router | Unifi (optionally Technitium later) |
| TLS termination + route hostname → service port | NPM | NPM (unchanged, but thinner) |
| Wildcard cert issuance (DNS-01 via Cloudflare) | NPM/certbot | NPM (unchanged) |
| WAN port forwarding | Unifi router | Unifi (unchanged) |

### Current NPM inventory (captured 2026-08-13)

Source: generated configs under `/var/lib/containers/npm/data/nginx/` on the
proxy LXC (CTID 101, `192.168.1.176`). Note the live data path is
`/var/lib/containers/npm/`, not the `/root/` path in `docs/pve/proxy.md`.

14 proxy hosts, no TCP streams, no redirection hosts:

| Hostname | Forwards to | Scheme |
| --- | --- | --- |
| unraid.shaneplunkett.com | 192.168.1.132:80 | http |
| proxmox.shaneplunkett.com | 192.168.1.169:8006 | https |
| unifi.shaneplunkett.com | 192.168.1.1:443 | https |
| proxy.shaneplunkett.com | 192.168.1.176:81 (NPM admin) | http |
| overseer.shaneplunkett.com | 192.168.1.90:5055 | http |
| prowlarr.shaneplunkett.com | 192.168.1.90:9696 | http |
| nzb.shaneplunkett.com | 192.168.1.90:8080 | http |
| deluge.shaneplunkett.com | 192.168.1.90:8112 | http |
| radarr.shaneplunkett.com | 192.168.1.90:7878 | http |
| sonarr.shaneplunkett.com | 192.168.1.90:8989 | http |
| sonarranime.shaneplunkett.com | 192.168.1.90:8990 | http |
| docker.shaneplunkett.com | 192.168.1.158:3000 | http |
| proxy.tail1d49f8.ts.net | 192.168.1.158:3000 | http |
| coffee.shaneplunkett.com | 192.168.20.29:80 (no TLS cert) | http |

**Certificate:** one Let's Encrypt wildcard (`npm-5`) covering
`*.shaneplunkett.com` and `*.shaneplunkett.dev`, ECDSA P-384, renewed via
**DNS-01 with the Cloudflare plugin** (`authenticator = dns-cloudflare`),
expiry 13 Sep 2026. Because renewal is DNS-01, ports 80/443 do not need to
be reachable from the internet — and indeed they are not forwarded.

### Current Unifi port forwarding (captured 2026-08-13)

Source: Unifi Network API (`/proxy/network/api/s/default/rest/portforward`)
on the gateway at `192.168.1.1`. Exactly one rule:

| Name | WAN port | Forwards to | Protocol | Enabled |
| --- | --- | --- | --- | --- |
| Plex | 32400 | 192.168.1.237:32400 | tcp+udp | yes |

NPM is therefore **not internet-facing at all** — it serves LAN (and
Tailscale) clients only. That confirms the plan: Technitium takes over the
naming layer, NPM stays as a thin internal TLS/router layer, and nothing
about WAN exposure changes.

### Current Unifi static DNS records (captured 2026-08-13)

Source: Unifi Network API
(`/proxy/network/v2/api/site/default/static-dns`). This is how the internal
names resolve today — the Unifi gateway answers them locally; they are not
in public DNS. All 16 are A records pointing at **192.168.1.176** (the NPM
LXC), all enabled:

`unraid`, `proxmox`, `unifi`, `auth`, `proxy`, `overseer`, `prowlarr`,
`nzb`, `deluge`, `radarr`, `sonarr`, `sonarranime`, `mcp-memory`,
`pihole`, `coffee`, `docker` — all `.shaneplunkett.com`.

Deltas between the two inventories worth resolving during migration:

- **In Unifi DNS but with no NPM proxy host:** `auth`, `mcp-memory`,
  `pihole`. These resolve to NPM but NPM has no route for them, so they hit
  the default host. Likely stale (`pihole` in particular) — decide whether
  to carry them over or drop them.
- **In NPM but not Unifi DNS:** `proxy.tail1d49f8.ts.net` (resolved by
  Tailscale MagicDNS, not the LAN resolver — unaffected by this migration).

### Migration notes specific to this setup

- The 16 Unifi static A records are the exact migration surface: recreate
  them in a Technitium primary zone for `shaneplunkett.com` — or replace
  the lot with a single wildcard `*.shaneplunkett.com → 192.168.1.176` —
  then point the Unifi DHCP scopes' DNS option at the Technitium LXC.
  Keep the Unifi records in place until Technitium is proven; they only
  answer clients that still use the gateway as their resolver, so the two
  can coexist during cutover.
- The Plex forward and NPM's cert renewal are untouched by any of this —
  neither depends on the DNS layer moving.
- Watch-item: a local primary zone for `shaneplunkett.com` makes Technitium
  authoritative for the whole domain on the LAN, so any record that exists
  only in Cloudflare must be duplicated into the local zone or handled with
  the Split Horizon app per-name — otherwise LAN clients lose it. The
  Cloudflare zone contents as of 2026-08-13 are below.

### Tailscale integration — decided direction (2026-08-13)

Goal: tailnet + home LAN behave as one shared network, with
`shaneplunkett.com` names working identically on both. Verified against
Tailscale's docs:

- **Custom MagicDNS domain is not possible.** MagicDNS "does not currently
  support the addition of arbitrary custom records," and the tailnet's
  `tail1d49f8.ts.net` name can only be swapped for another randomly
  generated ts.net name, not an owned domain
  ([MagicDNS](https://tailscale.com/docs/features/magicdns),
  [tailnet name](https://tailscale.com/docs/concepts/tailnet-name)). The
  domain-everywhere goal is met by Technitium serving the zone to tailnet
  clients instead; MagicDNS stays enabled for ts.net fallback.
- **Subnet router** on the pve node:
  `tailscale up --advertise-routes=192.168.1.0/24`, approve the route in
  the admin console, and disable key expiry on server nodes
  ([subnet routers](https://tailscale.com/docs/features/subnet-routers)).
  **`--accept-routes` belongs ONLY on Linux devices that live outside the
  LAN** (hetzvps). Learned the hard way (2026-08-13): enabling it on a
  LAN-resident machine (desktop, cube) makes the kernel route local
  traffic through the tunnel via pve — small packets survive the hairpin,
  but MTU-sensitive UDP (game traffic) times out, and once any machine
  flips back the asymmetry can black-hole LAN TCP entirely (cube was
  unreachable over LAN until fixed via Tailscale SSH). macOS/iOS accept
  routes automatically and hairpin the same way at home — imperceptible
  for light use, but suspect it first if Mac LAN transfers feel slow.
  Note: pve also needed `net.ipv4.ip_forward=1` (persisted in
  `/etc/sysctl.d/99-tailscale.conf`).
- **Tailnet DNS**: either set Technitium's Tailscale IP as the tailnet's
  global nameserver with **Override DNS servers** (all devices use it
  exclusively, everywhere — internal names + ad blocking on the go), or
  scope it with a split-DNS policy for `shaneplunkett.com` only
  ([DNS in Tailscale](https://tailscale.com/docs/reference/dns-in-tailscale),
  [split DNS policies](https://tailscale.com/docs/features/split-dns-policies)).
  Global override is the chosen shape; note it makes Technitium's uptime
  matter to every device, wherever it is — the second clustered instance
  (section 7) stops being optional nice-to-have if this is enabled.
- With the subnet route in place, all zone records point at **LAN IPs
  only** — no Split Horizon needed, remote clients reach the LAN addresses
  through the route. One zone, one set of answers.
- **Proxmox LXC caveat:** PVE injects `nameserver 100.100.100.100` +
  ts.net search domain into a tailnet-joined LXC's `/etc/resolv.conf`
  ([Proxmox troubleshooting](https://tailscale.com/docs/reference/troubleshooting/containers/proxmox)).
  For the Technitium LXC itself, make sure its own upstream resolution
  doesn't loop through Tailscale DNS once it becomes the tailnet
  nameserver (set the LXC's resolv.conf to localhost/root-server
  resolution, and run `tailscale up --accept-dns=false` on that node).
- Tailnet cleanup while at it: remove long-offline nodes (`sftp` ~127 d,
  `ipad166` ~149 d), disable key expiry on the server LXCs (proxy, mcphub,
  technitium when built), and prefer tags over user-owned keys for
  infrastructure nodes so they survive credential rotation
  (pve and cube are already tagged; proxy and mcphub are not).

### Cloudflare public records (captured 2026-08-13)

Source: Cloudflare API, read using the certbot DNS-01 token already on the
proxy LXC.

`shaneplunkett.com`:

| Type | Name | Content | Proxied |
| --- | --- | --- | --- |
| A | @ (apex) | 203.55.150.108 | yes |
| CNAME | collabora | → apex | yes |
| CNAME | kimai | → apex | yes |
| CNAME | nextcloud | → apex | yes |
| CNAME | overseerr | → apex | yes |
| CNAME | redbook | red-book-5nn.pages.dev | yes |
| TXT | @, _dmarc, *._domainkey | SPF `-all`, DMARC reject, empty DKIM (no-mail lockdown) | — |

Likely-stale alert: `collabora`, `kimai`, `nextcloud`, and `overseerr`
resolve (proxied) to the apex IP, but the Unifi WAN has **no 80/443 port
forward**, so these public names cannot reach an origin today. They look
like leftovers from an earlier setup — candidates for deletion rather than
duplication into the local zone. `redbook` (Cloudflare Pages) and the TXT
records are the only ones doing live work; if the local zone is a full
primary zone, `redbook` needs a matching CNAME locally (the TXT records
only matter to external mail servers, which never ask the LAN resolver).
Note the public `overseerr` (double-r) is a different name from the local
`overseer` (single-r) — no collision.

`shaneplunkett.dev`: apex + wildcard A → 43.224.183.64 (Hetzner VPS),
`vex` → a Cloudflare Tunnel, plus iCloud mail MX/SPF/DKIM/DMARC. Not
affected by a local `shaneplunkett.com` zone, but remember the NPM wildcard
cert also covers `*.shaneplunkett.dev`.
