# Proxmox nodes

Config that lives on the Proxmox hosts themselves, outside Terraform and Nix.

## TUN for containers

`90-homelab-tun.conf` gives every container on a node `/dev/net/tun`, so
Tailscale can run in kernel mode. Every container includes
`common.conf.d` through `common.conf`, so there's nothing per-container.

Install it on each node, and again after rebuilding one:

```sh
scp proxmox/90-homelab-tun.conf root@<node>:/usr/share/lxc/config/common.conf.d/
```

Running containers only pick it up when they restart.

Why it's done this way:

- Proxmox only lets `root@pam` set device passthrough. API tokens are refused,
  even root's, so Terraform's token can't add `dev0` and CI never could.
- A container with both `dev0: /dev/net/tun` and this drop-in fails to start.
  PVE's autodev hook creates the device for `dev0` and dies when the bind
  mount already made it. Don't add `dev0` for TUN anywhere.
- No package owns the file, so Proxmox upgrades leave it alone.

## Notifications to Discord

Proxmox sends its notifications, like the daily "packages available" and
backup results, to the homelab alerts channel through a webhook target named
`discord`, and the `to-discord` matcher routes everything to it. They're
cluster-wide, so they cover both nodes. The webhook's ID and token are a
Proxmox secret, and the body only carries the title and severity, because a
full package list goes past Discord's message limit.

To make them again, from `modules/agenix` in this repo:

```sh
url=$(agenix -d discord-webhook.age | cut -d= -f2-)
body=$(printf '%s' '{"username":"Proxmox","embeds":[{"title":{{ json title }},"description":{{ json severity }}}]}' | base64 -w0)
printf '%s\n' "${url#*/webhooks/}" | ssh shane@<node> "sudo bash -c 'read -r token
pvesh create /cluster/notifications/endpoints/webhook --name discord --method post \
  --url \"https://discord.com/api/webhooks/{{ secrets.webhook }}\" \
  --header \"name=Content-Type,value=\$(printf %s application/json | base64 -w0)\" \
  --body $body --secret \"name=webhook,value=\$(printf %s \"\$token\" | base64 -w0)\"
pvesh create /cluster/notifications/matchers --name to-discord --target discord'"
unset url
```

- **The URL has to look like a URL.** Proxmox rejects one that's only a
  template, so the public part stays in the URL and only the ID and token
  are a secret.
- **Matchers and targets share names**, so the matcher can't also be called
  `discord`.

## Upgrading the nodes

Proxmox's daily check posts to Discord when packages are waiting. Upgrade one
node at a time, Cube first, and only start the second once the first is back
and the cluster is quorate again, because with two nodes the cluster loses
quorum while either one is down.

```sh
ssh shane@<node> 'sudo apt-get -s full-upgrade | grep -E "^Remv|upgraded"'
ssh shane@<node> 'sudo systemd-run --unit=pve-upgrade --collect --setenv=DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=--force-confold full-upgrade'
ssh shane@<node> 'sudo journalctl -fu pve-upgrade'
ssh shane@<node> 'sudo systemctl reboot'
```

The dry run is there to catch anything being removed, which a normal upgrade
never does. Running the upgrade as its own unit means a dropped SSH session
can't interrupt dpkg. The old kernel stays installed, so if a new one
misbehaves, `proxmox-boot-tool kernel pin <version>` and a reboot goes back.

Before rebooting PVE:

- **Stop Unraid from its own UI first.** It has no guest agent, so Proxmox
  can only press its power button and force it off if the array takes too
  long to stop, which means a parity check.
- **Check Unraid's array started.** Auto start is on in Disk Settings, but
  if it's ever off, nothing can mount its shares until someone starts it.
- **Then remount its shares on Cube**, because they go stale whenever
  Unraid restarts. `docs/cube/README.md` has the commands.
