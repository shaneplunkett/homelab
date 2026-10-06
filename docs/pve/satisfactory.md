# Satisfactory dedicated server LXC

## Summary

Alpine LXC on PVE running a Satisfactory dedicated server through
`wolveix/satisfactory-server`. The LXC is declared in
`terraform/pve-satisfactory.tf`, and the deployment files are in
`stacks/pve/satisfactory-lxc/`, installed under `/opt/satisfactory` in the LXC.
Its MAC is pinned in Terraform so the Unifi DHCP reservation keeps handing out
the same address.

Apply only this workload:

```bash
terraform -chdir=terraform plan -target=module.satisfactory -out=/tmp/satisfactory.tfplan
terraform -chdir=terraform apply /tmp/satisfactory.tfplan
```

## Bootstrap

After Terraform creates the LXC (`<vmid>` is the `vm_id` in
`terraform/pve-satisfactory.tf`):

```bash
ssh shane@pve
sudo pct exec <vmid> -- apk add --no-cache docker docker-cli-compose restic openssh-client curl tzdata
sudo pct exec <vmid> -- rc-update add docker default
sudo pct exec <vmid> -- service docker start
sudo pct exec <vmid> -- ln -snf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
sudo pct exec <vmid> -- sh -c 'echo Australia/Melbourne > /etc/timezone'

sudo pct exec <vmid> -- mkdir -p /opt/satisfactory
# Copy docker-compose.yml and backup.sh from stacks/pve/satisfactory-lxc/.
sudo pct exec <vmid> -- chmod 0755 /opt/satisfactory/backup.sh
# Run these on PVE, not inside the unprivileged LXC. The network buffer sysctls
# are host-owned and the container cannot raise them itself.
printf '%s\n' \
  'net.core.rmem_max=2621440' \
  'net.core.wmem_max=2621440' | sudo tee /etc/sysctl.d/99-game-servers.conf
sudo sysctl -p /etc/sysctl.d/99-game-servers.conf

sudo pct exec <vmid> -- docker compose --project-directory /opt/satisfactory up -d
```

First boot downloads the server with SteamCMD and can take more than ten
minutes. It's ready when the container health check reports `healthy` and the
log shows `Game Engine Initialized`.

## Backups

`backup.sh` snapshots the save/settings tree and deployment files to restic on
the Hetzner Storage Box. Cron remains LXC state and must be restored after a
rebuild:

```cron
0 */6 * * * /opt/satisfactory/backup.sh >> /var/log/satisfactory-backup.log 2>&1
```

## Gotchas

- Use both TCP and UDP 7777. Current wolveix releases also use TCP 8888 for
  server messaging.
- Keep host networking. The prior bridge setup caused UDP timeouts.
- The wolveix startup scripts regenerate `Engine.ini`, so hand edits there do
  not survive a restart. Keep the bandwidth values in Compose's `command` list.
- The server is LAN-only unless a router rule is added separately.
