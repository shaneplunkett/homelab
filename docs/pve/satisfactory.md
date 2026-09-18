# Satisfactory dedicated server LXC

## Summary

Alpine LXC 106 on PVE running a fresh Satisfactory dedicated server through
`wolveix/satisfactory-server`.

- Hostname: `satisfactory`
- Address: `192.168.1.96` from the retained DHCP reservation
- OS: Alpine 3.22
- Cores: 6
- RAM: 24 GB
- Swap: 4 GB
- Disk: 50 GB on `local-lvm`
- Network: host networking, with game/API traffic on TCP and UDP 7777 and
  messaging on TCP 8888
- Boot on start: yes
- Game branch: main/stable with `STEAMBETA=false`
- Players: 8

This deployment started with an empty `/opt/satisfactory/config` tree. No save
from the retired server was restored.

## Connecting

On the LAN, add the server in Satisfactory at:

```text
192.168.1.96:7777
```

The container uses `network_mode: host`. The game binds directly to the LXC's
interface rather than sending its UDP traffic through Docker NAT.

## Infrastructure

`terraform/pve-satisfactory.tf` declares the LXC. VMID 106 and MAC address
`BC:24:11:81:EA:CC` are explicit so the existing Unifi reservation continues
to assign `192.168.1.96`.

Apply only this workload:

```bash
terraform -chdir=terraform plan -target=module.satisfactory -out=/tmp/satisfactory.tfplan
terraform -chdir=terraform apply /tmp/satisfactory.tfplan
```

## Stack

The repo-managed deployment files are in `stacks/pve/satisfactory-lxc/` and
are installed under `/opt/satisfactory` in the LXC.

The Compose file keeps the server on the stable branch, updates it at every
container start, and stores game files, settings, saves, and the image's own
save copies beneath `/opt/satisfactory/config`.

The Unreal bandwidth settings remain Compose launch arguments. The wolveix
startup scripts regenerate `Engine.ini`, so hand edits there do not survive a
restart.

## Bootstrap

After Terraform creates the LXC:

```bash
ssh shane@pve
sudo pct exec 106 -- apk add --no-cache docker docker-cli-compose restic openssh-client curl tzdata
sudo pct exec 106 -- rc-update add docker default
sudo pct exec 106 -- service docker start
sudo pct exec 106 -- ln -snf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
sudo pct exec 106 -- sh -c 'echo Australia/Melbourne > /etc/timezone'

sudo pct exec 106 -- mkdir -p /opt/satisfactory
# Copy docker-compose.yml and backup.sh from stacks/pve/satisfactory-lxc/.
sudo pct exec 106 -- chmod 0755 /opt/satisfactory/backup.sh
# Run these on PVE, not inside the unprivileged LXC. The network buffer sysctls
# are host-owned and the container cannot raise them itself.
printf '%s\n' \
  'net.core.rmem_max=2621440' \
  'net.core.wmem_max=2621440' | sudo tee /etc/sysctl.d/99-game-servers.conf
sudo sysctl -p /etc/sysctl.d/99-game-servers.conf

sudo pct exec 106 -- docker compose --project-directory /opt/satisfactory up -d
```

First boot downloads the server with SteamCMD and can take more than ten
minutes.

## Verification

```bash
sudo pct exec 106 -- docker ps --filter name=satisfactory
sudo pct exec 106 -- docker logs --tail 100 satisfactory
sudo pct exec 106 -- docker inspect satisfactory --format '{{json .State.Health}}'
sudo pct exec 106 -- sh -c 'ss -lntup | grep -E ":(7777|8888)\\b"'
terraform -chdir=terraform plan -target=module.satisfactory
```

The server is ready when the container health check reports `healthy`, the log
shows `Game Engine Initialized`, and the listeners exist.

## Saves

The new live save tree is:

```text
/opt/satisfactory/config/saved/server/
```

Server settings live under `/opt/satisfactory/config/saved`. The image's
copied save backups live under `/opt/satisfactory/config/backups`.

## Backups

`backup.sh` snapshots the live save/settings tree, the image's copied backups,
and the deployment files to the existing `./satisfactory` restic repository on
the Hetzner Storage Box. Old snapshots remain available for disaster recovery,
but nothing restores them into this fresh server.

- Schedule: every six hours
- Retention: keep last 8, 14 daily, and 4 weekly
- Credentials: `/root/.restic-password` and `/root/.ssh/id_ed25519`
- Log: `/var/log/satisfactory-backup.log`

Cron remains LXC state and must be restored after a rebuild:

```cron
0 */6 * * * /opt/satisfactory/backup.sh >> /var/log/satisfactory-backup.log 2>&1
```

## Updating

The game updates whenever the container starts because `SKIPUPDATE=false`.
To update the wrapper image too:

```bash
docker compose --project-directory /opt/satisfactory pull
docker compose --project-directory /opt/satisfactory up -d
```

## Gotchas

- Use both TCP and UDP 7777. Current wolveix releases also use TCP 8888 for
  server messaging.
- Keep host networking. The prior bridge setup caused UDP timeouts.
- Do not edit the generated bandwidth values in `Engine.ini`; keep them in
  Compose's `command` list.
- The server is LAN-only unless a router rule is added separately.
