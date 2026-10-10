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

## Zigbee

Zigbee2MQTT and Mosquitto run natively on the host, from nixpkgs. Zigbee2MQTT
reaches the SLZB-06P7 coordinator over TCP on the IoT VLAN, and hands devices
to Home Assistant through Mosquitto, which only listens on localhost. Its
frontend is the `zigbee` route, behind the oauth2-proxy gate.

- **The network is on channel 15.** The Wi-Fi's 2.4 GHz is on channel 11,
  which crowds Zigbee 20 to 25. The Hue bridge sat on 25, and its far lights
  kept dropping off.
- **Never lose or change the network key.** It's `zigbee2mqtt-network-key`
  in Bitwarden and `zigbee2mqtt-secret` in agenix. Zigbee2MQTT reads it from
  `secret.yaml`, a symlink to the agenix secret, so it stays out of the Nix
  store. A new key means re-pairing every device. The PAN IDs are in Nix and
  matter just as much.
- **Nix rewrites `configuration.yaml` on every start,** so settings changed in
  the frontend don't survive a restart. Put them in Nix. Devices and groups
  live in `devices.yaml` and `groups.yaml`, which Nix leaves alone.
- **`version` is pinned** to the current config version, so Zigbee2MQTT
  doesn't try to migrate the file Nix writes.
- The backup covers `/var/lib/zigbee2mqtt`, including the coordinator backup
  Zigbee2MQTT keeps, which is what moves the network to a new coordinator.
