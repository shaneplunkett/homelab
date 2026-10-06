# Homelab

Infrastructure for a two-node Proxmox cluster (PVE and Cube) plus a little
Hetzner and Cloudflare. Terraform creates the containers, Nix configures what
runs inside them. What's actually deployed is whatever the code says, so this
README only covers how the pieces fit together.

## Layout

```
flake.nix          colmena hive, dev shell, and the base LXC template
modules/
  base.nix         every NixOS LXC: Proxmox LXC support, SSH, node exporter
  agenix/          secrets, their recipients, and the homelab.secrets option
  hosts/<host>.nix which services a host runs
  services/<name>/ one folder per service
terraform/         Proxmox LXCs/VMs, Hetzner, Cloudflare
proxmox/           config installed on the Proxmox nodes themselves
stacks/            legacy Docker Compose configs for Alpine LXCs
docs/              notes that the code can't explain
tools/             small helpers (minirack planner, Cloudflare MCP headers)
```

## Nix hosts

Each NixOS LXC is a node in the colmena hive in `flake.nix`. Defaults every
node gets live in `colmenaHive.defaults`; a host's own file under
`modules/hosts/` just imports the services it runs.

Modules can read the whole hive through colmena's `nodes` and `name`
arguments, so things like scrape targets, log shipping and dashboard tiles are
generated from the hive instead of kept as hand-written lists.

```sh
colmena build --on <host>   # check it evaluates and builds
colmena apply --on <host>   # deploy over SSH
```

Flakes only see tracked files, so `git add` new files before building.

### Adding a host

1. Build the template if it's changed:
   `nix build .#nixosConfigurations.base.config.system.build.tarball`, and
   upload it to each node's `local:vztmpl` under the name
   `terraform/modules/nixos-lxc` expects.
2. Add a `terraform/<node>-<host>.tf` using `modules/nixos-lxc` and apply it.
3. Give it a fixed DHCP reservation in UniFi.
4. Add `modules/hosts/<host>.nix` and a node in the hive pointing at it.
5. Add the host's key to `modules/agenix/agenix-rules.nix`
   (`ssh-keyscan -t ed25519 <ip>`), add it to the secrets it needs, and
   `agenix -r` to rekey.
6. `colmena apply --on <host>`.

## Secrets

agenix, with recipients in `modules/agenix/agenix-rules.nix`. A module asks
for secrets by name with `homelab.secrets = [ "name" ];` and reads the path
from `config.age.secrets.<name>.path`. Values come from rbw and are piped
straight in, so they never land on disk or in shell history:

```sh
cd modules/agenix
printf 'KEY=%s\n' "$(rbw get <entry>)" | agenix -e <name>.age
```

Whether a secret is a raw value or a `KEY=value` env file depends on what the
consuming service expects.

## Monitoring

Prometheus, Alertmanager, Loki and Grafana run on the monitoring host. Every
Nix host is scraped and ships its journal to Loki automatically. Alert rules
live next to the service they watch, and everything routes through
Alertmanager to Discord. Gatus on the dashboard host watches the monitoring
stack itself, so a dead Alertmanager still gets noticed.

## Ingress

nginx on the ingress host terminates TLS with a wildcard certificate (ACME
DNS-01 via Cloudflare) and proxies `<name>.shaneplunkett.com` to each
service. Routes are an attrset in `modules/services/nginx-ingress`; anything
unknown gets a 404. On the LAN, Blocky resolves the whole domain to the
ingress host.

## Updates

Nix hosts: `nix flake update`, build, then `colmena apply`. Legacy Alpine
LXCs upgrade themselves nightly via apk-cron (`terraform/modules/lxc-baseline`)
until they're migrated.

## Tools

- [minirack](tools/minirack/README.md): a visual planner for the 10" minirack
  layout and cabling. Run `bun tools/minirack/server.ts`.
