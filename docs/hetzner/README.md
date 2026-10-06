# Hetzner

A Hetzner Storage Box is the offsite restic target for homelab backups. It's
defined in `terraform/hetzner.tf`, with state in Terraform Cloud and applies
run locally from `terraform/`.

## Nix host backups

Nix hosts are rebuilt from git, so only their data is backed up. A service
lists its data with `homelab.backup.paths` (plus `exclude` and a `prepare`
step for things like database dumps), and any host with paths gets three
restic jobs from `modules/services/backup`: a daily backup, a weekly prune
and a weekly partial check. They share a lock, so maintenance waits for a
backup instead of failing it.

Each host has its own Storage Box subaccount (`terraform/hetzner.tf`), which
only sees its own folder, and its own restic repo inside it. restic reaches
the box through rclone's SFTP backend, because subaccounts only take
passwords. The host's agenix secret `backup-<host>` holds its restic password
and subaccount login.

### Adding a host

1. Add it to `local.backup_hosts` in `terraform/hetzner.tf` and apply.
2. Make it a restic password: `rbw generate --no-symbols 48 restic-<host> > /dev/null`.
3. Add `backup-<host>.age` to `modules/agenix/agenix-rules.nix` with
   the host as a recipient, then from `modules/agenix`:

   ```sh
   host=<host>
   login=$(terraform -chdir=../../terraform output -json storage_box_subaccounts)
   {
     printf 'RESTIC_PASSWORD=%s\n' "$(rbw get "restic-$host")"
     printf 'RCLONE_SFTP_USER=%s\n' "$(jq -r --arg h "$host" '.[$h].username' <<<"$login")"
     printf 'RCLONE_SFTP_PASS=%s\n' "$(jq -r --arg h "$host" '.[$h].password' <<<"$login" | rclone obscure -)"
   } | agenix -e "backup-$host.age"
   unset login
   ```

4. Give a service on the host some `homelab.backup.paths` and deploy.

### Restoring a host's data

On the host, `restic-homelab` is restic with the host's repo and
credentials already set:

```sh
restic-homelab snapshots
systemctl stop <service>
restic-homelab restore latest --target / --include <path>
systemctl start <service>
```

If the host is gone, rebuild it first (the README's "Adding a host"), and its
secret will decrypt once its new key is a recipient and the secrets are
rekeyed. To read a repo from a laptop instead, set the same variables by
hand in the dev shell, which has restic and rclone:

```sh
export RESTIC_REPOSITORY=rclone::sftp:restic RCLONE_SFTP_HOST=<box> RCLONE_SFTP_PORT=23
export RCLONE_SFTP_USER=... RCLONE_SFTP_PASS=... RESTIC_PASSWORD=...
restic snapshots
```

A service with a `prepare` step backs up a dump rather than its live files,
so restore that and put it back in place. For Gatus, that means copying
`backup.db` over `data.db` while Gatus is stopped.

### Monitoring

Each job stamps its last success into node exporter's textfile directory,
and `modules/services/backup/monitoring.nix` alerts when a stamp goes stale
or a host that backs up has never succeeded. The monitoring host also probes
the box over SFTP and polls Hetzner's API for usage, since a full box fails
every host at once.

## Legacy LXC backups

Each Alpine LXC that backs up runs its own repo-managed script from cron
(`stacks/**/backup.sh`, installed under `/opt/<service>/`). They share one
restic repo and password on the main account; each LXC has its own SSH key
on the box. The scripts are the source of truth for what's backed up, when,
and for how long.

Final archives of retired services are kept on the box under
`<service>-final-archives/`.

## Gotchas

- **`TF_VAR_ssh_public_key` must be set** (the repo `.envrc` does it). Without
  it, plan wants to destroy and recreate the Storage Box.
- **Keep the restic password to letters and digits.** systemd reads the
  host's secret as an env file and the `restic-homelab` wrapper sources it
  with bash, and the two disagree about quotes and symbols.
- **List every host key type of the box** in known_hosts. rclone accepts
  whichever one the box offers, and a missing type is a "key mismatch".
- **The SFTP probe is IPv4.** Blackbox prefers IPv6, the box has an AAAA
  record, and the LXCs have no IPv6 route.
- **Subaccount usernames come from Hetzner** (`<box>-subN`), so they live in
  each host's secret rather than in Nix.
- **The usage API needs a token**, kept as the `hetzner-api-token` secret on
  the monitoring host. A read-only token is enough.
- **Back up real paths, not symlinks.** Services with `DynamicUser` keep
  their state in `/var/lib/private/<name>`, and `/var/lib/<name>` is a
  symlink restic would store as just a link.
- **Nothing under `/mnt` gets backed up.** That's where Proxmox mounts the
  Unraid shares, so the module refuses those paths and restic stays on one
  filesystem.
- **Legacy LXC SSH keys are added out-of-band.** Terraform ignores `ssh_keys` changes
  after creation, so each LXC's key is appended to the box's
  `authorized_keys` by hand.
- **SFTP paths must be relative**: `./backups`, not `/backups`.
- **SSH is on port 23**, not 22.
- **Legacy cron lives on the LXC**, not in config, so a rebuilt container
  needs it restored.
- **A legacy backup only runs while its LXC is healthy.** The restic repo survives
  losing a container, but new dumps stop until it's back.
