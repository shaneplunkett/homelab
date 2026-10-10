# Home

NixOS LXC on PVE running Home Assistant at `https://home.shaneplunkett.com`.
The container is `module "home"` in `terraform/pve-home.tf`, and the service is
`modules/services/home-assistant`. The plan for moving the apartment onto it is
in [the research notes](../research/home-assistant.md).

## Why a container image

Home Assistant runs from the official image under podman, not the nixpkgs
module. The nixpkgs build has no pip, so every new integration would need a
PR before it could be added, and HACS can't work at all. Most of Home
Assistant's config lives in its UI anyway. Renovate bumps the image tag.

It uses host networking, because discovery and HomeKit Controller pairing
need mDNS.

## First setup

Home Assistant blocks requests from a reverse proxy until it's told to trust
one, so the first visit has to skip the ingress:

1. Open the host's LAN address on port 8123 and create the owner account.
2. Under Settings, System, Network, turn on "Trust X-Forwarded-For" and add
   the ingress host's address to "Trusted proxies".
3. From then on, use `https://home.shaneplunkett.com`.

These settings live in the UI, not `configuration.yaml`. A YAML
`http:` block only gets imported once, and then a repair asks you to delete it.

## Backups

The recorder database is copied with SQLite's `.backup` to `backup.db` before
restic runs, and the live file is excluded. To restore, put `backup.db` back as
`home-assistant_v2.db` with `podman-homeassistant` stopped. Home Assistant's own
`backups` folder is excluded, because restic already covers everything in it.
