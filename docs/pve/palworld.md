# Palworld Dedicated Server LXC

## Summary

Alpine LXC container on PVE running the official Palworld dedicated-server
Docker image.

- **VMID:** 106
- **Hostname:** palworld
- **Address:** `192.168.1.96` (DHCP reservation retained through the declared MAC)
- **OS:** Alpine 3.22
- **Cores:** 6
- **RAM:** 24 GB
- **Swap:** 4 GB
- **Disk:** 50 GB on local-lvm
- **Network:** DHCP on `vmbr0`; `8211/udp` published by Docker
- **Boot on start:** yes
- **Players:** 8

The sizing is intentionally unchanged from the retired Satisfactory LXC. It
exceeds Palworld's official 4-core and 16 GB recommendations while leaving
headroom beneath the LXC's 24 GB memory limit.

## Connecting

The server is LAN-only (also reachable over the tailnet via the subnet
route). In Palworld, join a multiplayer game with:

```text
palworld.shaneplunkett.com:8211
```

The name is an explicit A record in the Technitium `shaneplunkett.com` zone
pointing straight at this LXC (192.168.1.96) — it deliberately bypasses the
NPM wildcard because game traffic is raw UDP, not HTTP. Joining by IP
(`192.168.1.96:8211`) still works.

No router port-forward is declared. Add one separately only if the server
should be reachable from outside the LAN.

## Infrastructure

`terraform/pve-palworld.tf` declares the LXC. VMID 106 and the former
Satisfactory LXC's MAC address are explicit so the replacement retains its
DHCP reservation instead of silently moving to a new address.

### Destructive migration gate

Before replacing a game-server LXC:

1. stop or save the old game server cleanly
2. run its offsite backup and record the resulting restic snapshot ID
3. list or restore-check that snapshot
4. create and verify a whole-LXC `vzdump` archive
5. preserve the restic password and storage-box SSH key outside the LXC
6. review a saved Terraform plan that contains only the intended replacement

For the 31 July 2026 migration, the final Satisfactory restic snapshot is
`e183edff` in the preserved `./satisfactory` repository. Its save tree was
restore-checked before replacement. A second recovery path remains on PVE:

```text
/var/lib/vz/dump/vzdump-lxc-106-pre-palworld-20260731T004726Z.tar.zst
```

The root-only migration-credential bundle is:

```text
/var/lib/vz/dump/lxc-106-pre-palworld-secrets-20260731T004715Z.tgz
```

Apply only this workload:

```bash
terraform -chdir=terraform plan \
  -replace=module.palworld.proxmox_virtual_environment_container.this \
  -target=module.satisfactory.proxmox_virtual_environment_container.this \
  -target=module.palworld \
  -out=/tmp/palworld.tfplan

terraform -chdir=terraform apply /tmp/palworld.tfplan
```

Save the reviewed plan to `/tmp/palworld.tfplan` with `-out` before applying
it. The extra old-module target is needed only for this first replacement so
Terraform can process the `moved` block from `module.satisfactory` to
`module.palworld`.

## Stack

`stacks/pve/palworld-lxc/` contains:

- `docker-compose.yml` — the version-pinned official Palworld image
- `palserver-entrypoint.sh` — an adapted ownership-fixing entrypoint that runs
  PalServer as PID 1 so Docker can stop it cleanly
- `backup.sh` — a consistent save backup to Hetzner via restic

The Compose launch arguments declare UDP port 8211 and an eight-player cap.
The legacy `-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS`
arguments are deliberately omitted: Pocketpair's current v1.0 documentation
says leaving them unset may improve performance. Save and configuration data
persist beneath `/opt/palworld/Saved`. Compose overrides Docker's default stop
signal with `SIGINT`, which is the same signal as Ctrl+C and lets PalServer
save and exit cleanly.

## Bootstrap

After Terraform creates the LXC:

```bash
ssh shane@pve
sudo pct exec 106 -- apk add --no-cache docker docker-cli-compose restic openssh-client curl tzdata
sudo pct exec 106 -- rc-update add docker default
sudo pct exec 106 -- service docker start
sudo pct exec 106 -- ln -snf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
sudo pct exec 106 -- sh -c 'echo Australia/Melbourne > /etc/timezone'

sudo pct exec 106 -- mkdir -p /opt/palworld/Saved
# Copy docker-compose.yml, palserver-entrypoint.sh, and backup.sh from
# stacks/pve/palworld-lxc/ into /opt/palworld.
sudo pct exec 106 -- chmod 0755 /opt/palworld/palserver-entrypoint.sh /opt/palworld/backup.sh

# Restore /root/.restic-password and /root/.ssh from the root-only migration
# bundle or another secure copy, then enforce root-only permissions.
sudo pct exec 106 -- chmod 0700 /root/.ssh
sudo pct exec 106 -- chmod 0600 /root/.restic-password /root/.ssh/id_ed25519

# Existing rebuild: this must list the Palworld repository.
sudo pct exec 106 -- sh -c \
  'RESTIC_REPOSITORY="sftp:u558795@u558795.your-storagebox.de:./palworld" \
   RESTIC_PASSWORD_FILE=/root/.restic-password \
   restic snapshots --option "sftp.args=-p 23"'
# First deployment only: use `restic init` with the same environment instead.

sudo pct exec 106 -- sh -c \
  '(crontab -l | grep -v "/opt/palworld/backup.sh"; echo "0 4 * * * /opt/palworld/backup.sh >> /var/log/palworld-backup.log 2>&1") | crontab -'
sudo pct exec 106 -- service crond restart
sudo pct exec 106 -- docker compose --project-directory /opt/palworld up -d
```

The image already contains the game server. First start still takes a little
while to initialise the save and configuration tree.

## Verification

After deployment or a rebuild:

```bash
# Correct image/version and published UDP port
sudo pct exec 106 -- docker ps --filter name=palworld-server
sudo pct exec 106 -- docker logs --tail 100 palworld-server

# PalServer must be PID 1 and listening on UDP 8211 (hex 2013)
sudo pct exec 106 -- docker exec palworld-server \
  sh -c 'grep -qx PalServer-Linux /proc/1/comm && grep -qi :2013 /proc/net/udp'

# A controlled stop should complete promptly through PalServer's SIGINT cleanup
sudo pct exec 106 -- docker compose --project-directory /opt/palworld stop -t 120
sudo pct exec 106 -- docker compose --project-directory /opt/palworld up -d

# Prove both backup creation and remote visibility
sudo pct exec 106 -- /opt/palworld/backup.sh
sudo pct exec 106 -- sh -c \
  'RESTIC_REPOSITORY="sftp:u558795@u558795.your-storagebox.de:./palworld" \
   RESTIC_PASSWORD_FILE=/root/.restic-password \
   restic snapshots --option "sftp.args=-p 23" --tag palworld --latest 1'

# The Terraform-owned LXC should be converged
terraform -chdir=terraform plan -target=module.palworld
```

## Settings and saves

The persistent tree is:

```text
/opt/palworld/Saved/
├── Config/LinuxServer/PalWorldSettings.ini
├── SaveGames/
└── ...
```

Game balance, server name, passwords, and similar settings live in
`PalWorldSettings.ini`. The port and player cap stay in Compose because
Palworld supports them as launch arguments.

## Updating

The image is deliberately version-pinned. Before changing it:

1. Run `/opt/palworld/backup.sh`.
2. Set the new official `ghcr.io/pocketpairjp/palserver:<game-version>` tag in
   `stacks/pve/palworld-lxc/docker-compose.yml`.
3. Copy the updated Compose file to `/opt/palworld/docker-compose.yml`.
4. Run `docker compose --project-directory /opt/palworld pull`.
5. Run `docker compose --project-directory /opt/palworld up -d`.
6. Verify the container log and UDP listener.

Pocketpair warns that client and dedicated-server versions must match.

## Backups

`backup.sh` pushes save data and the repo-managed deployment files to a
dedicated `./palworld` restic repository on the Hetzner Storage Box.

The script:

1. stops the game container with a two-minute grace period
2. snapshots `Saved/`, Compose, the entrypoint, and the backup script
3. applies retention
4. restarts the server even if restic fails
5. optionally pushes success or failure to Uptime Kuma when
   `/opt/palworld/.backup-kuma-url` exists

The controlled stop avoids taking a save snapshot while Palworld is writing
world data.

- **Schedule:** daily at 04:00 Australia/Melbourne
- **Retention:** keep last 8, 14 daily, and 4 weekly
- **Credentials:** `/root/.restic-password` plus the root SSH key; never store
  either in Git
- **Repository:** `sftp:u558795@u558795.your-storagebox.de:./palworld`, SFTP
  port 23

Cron remains host state and must be restored after an LXC rebuild:

```cron
0 4 * * * /opt/palworld/backup.sh >> /var/log/palworld-backup.log 2>&1
```

## Gotchas

- Palworld clients and the dedicated server must run compatible versions.
- Do not use `latest`; update the declared game-version tag intentionally.
- Do not expose UDP 8211 to the internet without explicitly deciding to make
  the server public.
- Keep `/opt/palworld/Saved` on the LXC's NVMe-backed storage. Pocketpair warns
  that slow storage can cause save corruption.
- Use `docker compose down` or `stop` rather than killing the LXC while the
  game is writing.
