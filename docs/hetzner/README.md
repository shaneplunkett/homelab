# Hetzner

A Hetzner Storage Box is the offsite restic target for homelab backups. It's
defined in `terraform/hetzner.tf`, with state in Terraform Cloud and applies
run locally from `terraform/`.

## Backups

Each LXC that backs up runs its own repo-managed script from cron
(`stacks/**/backup.sh`, installed under `/opt/<service>/`). They share one
restic repo and password; each LXC has its own SSH key on the box. The
scripts are the source of truth for what's backed up, when, and for how long.

Final archives of retired services are kept on the box under
`<service>-final-archives/`.

## Gotchas

- **`TF_VAR_ssh_public_key` must be set** (the repo `.envrc` does it). Without
  it, plan wants to destroy and recreate the Storage Box.
- **LXC SSH keys are added out-of-band.** Terraform ignores `ssh_keys` changes
  after creation, so each LXC's key is appended to the box's
  `authorized_keys` by hand.
- **SFTP paths must be relative**: `./backups`, not `/backups`.
- **SSH is on port 23**, not 22.
- **Cron lives on the LXC**, not in config, so a rebuilt container needs it
  restored.
- **A backup only runs while its LXC is healthy.** The restic repo survives
  losing a container, but new dumps stop until it's back.
