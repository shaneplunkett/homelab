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

## Backups

The recorder database is copied with SQLite's `.backup` to `backup.db` before
restic runs, and the live file is excluded. To restore, put `backup.db` back as
`home-assistant_v2.db` with `podman-homeassistant` stopped. Home Assistant's own
`backups` folder is excluded, because restic already covers everything in it.
