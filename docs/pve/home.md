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

## HACS

HACS isn't in Nix. It was installed once into the config volume with its
official script, and it updates itself from the UI after that:

```sh
ssh root@home 'podman exec homeassistant bash -c "wget -O - https://get.hacs.xyz | bash -"'
ssh root@home systemctl restart podman-homeassistant
```

Then add the HACS integration in the UI, which links it to GitHub with a
device code. Anything installed through HACS lives in `custom_components`,
so the backup covers it.

## Signing in

Home Assistant has no OIDC login of its own, so hass-oidc-auth (`auth_oidc`,
from HACS) adds a Pocket ID button. It isn't behind the oauth2-proxy gate,
because the iPhone app can't get through a proxy login.

- The Pocket ID client is `home`, with the callback
  `https://home.shaneplunkett.com/auth/oidc/callback`. Its secret is
  `home-oidc-client-secret` in Bitwarden.
- The client is configured in Home Assistant's UI, under Devices & services,
  so the secret lives in Home Assistant's own storage rather than agenix.
- Both the admin and user roles are `home_admins`, so nobody outside that group
  gets in at all.
- Automatic user linking was on only long enough to link the passkey to the
  existing owner account. Leave it off: it links by username alone.
- The iPhone app can't open the passkey page itself, so it shows a code. Start
  a fresh SSO login in a private window or in Safari, and after the passkey
  there's a screen to enter the code. Being signed in already doesn't show it.
  The app picks it up by itself.

**If Pocket ID is down,** the owner's password login still works. Pick the
other login method on the welcome screen. The password is in Bitwarden.
Sessions already signed in keep working, because Pocket ID is only used at
login.

## Reaching the IoT network

The smart home devices are on the IoT VLAN. One UniFi zone policy, "Home
Assistant to IoT", lets the home host into the IoT zone, with return traffic
allowed. IoT devices still can't start a connection to anything on the LAN.
Every IoT device has a fixed IP, so Home Assistant can find it even when mDNS
gets flaky.

## Vex's access

Vex has its own admin user, `Vex`, and a long-lived token in Bitwarden as
`home-assistant-vex-token`. The logbook shows what Vex did, and disabling the
user cuts it off without touching Shane's login.

Some changes are only on the websocket API, not REST: enabling an entity,
setting a device's area or name, and listing discovered devices.

## After a power cut

The "Turn things off after a power cut" automation turns off any light that
comes back on by itself. It leaves the Play bars alone, and only switches off
plugs listed in its `plugs` variable.

- It only acts in the first 20 minutes after pve boots. Home Assistant
  restarting, or a device dropping off Wi-Fi and coming back, isn't a power
  cut, and it would otherwise turn off a 3D printer mid-print.
- It reads pve's boot time from System Monitor's `sensor.system_monitor_uptime`.
  Inside podman, `/proc/uptime` is the Proxmox host's, not the LXC's, which is
  exactly the signal a power cut leaves. System Monitor turns that sensor off
  by default, so it has to be enabled.
- Lights without a power-on setting still flash on for a moment before it
  catches them.

## Scenes

Starlight is a Home Assistant scene copied from the Hue bridge's own scene
definition, so it survives the Play bars leaving the bridge. Hue's version
lives on the bridge as `scene.*_starlight`. Ours is `scene.starlight`.

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

## Thread

The Eve Aqua is a HomeKit-over-Thread device, paired to Home Assistant through
Apple's border routers (the HomePod and the Apple TV). Home Assistant reaches
the Thread network through the route those routers advertise.

- **The home host has to accept IPv6 router adverts.** Proxmox writes
  `IPv6AcceptRA = false` into the container's `eth0.network`, so the module
  adds a drop-in that turns it back on. Without the route, pairing fails with
  `NetworkError`.
- **Every Apple border router has to be on the main LAN.** When the Apple TV
  sat on the IoT VLAN, the Aqua's replies left through it and were dropped at
  the firewall, so pairing timed out. The same split is why the Apple TV kept
  reporting network issues.
- The Aqua is a sleepy battery device. Press its button to wake it before
  pairing.

## Moving devices over

- **Hue lights:** unplug the Hue bridge before resetting them. While it's
  running, half-reset lights drift back to it. With it off, a power-cycle reset
  (off 2 seconds, on 8, five times) or the Hue dimmer (power + Hue, about 10
  seconds) gets them into Zigbee2MQTT within seconds. Zigbee2MQTT's
  serial-number reset wipes every serial listed, including lights that have
  already joined.
- **HomeKit devices** (Meross, Sensibo, the Aqua) come over with HomeKit
  Controller: remove them from Apple Home, then pair with their code. Sensibo
  only shares on/off, mode and temperature that way, so the Sensibo cloud
  integration sits beside it for the flap and fan. The local one is hidden.
- **The balcony Shelly** runs the community shelly-homekit firmware, so it pairs
  through HomeKit Controller too. Its RPC `Shelly.SetConfig` reboots it without
  saving, so change settings in its web page, which is only reachable from the
  home host (`ssh -L 8115:<shelly>:80 root@home`). It's set to edge input and
  off after a power cut, and shows up as a light through Switch as X.

## Matter

The matter.js server, Home Assistant's current Matter stack, runs natively from
nixpkgs and listens for Home Assistant on localhost. Its storage holds the Matter
fabric's keys, so it's backed up. Losing it means re-sharing every Matter device.

Matter devices already in Apple Home join by sharing: in the Home app, open the
device's settings, turn on pairing mode, and give Home Assistant the code it
shows. The device stays in Apple Home as well.
