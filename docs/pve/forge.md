# Forge

NixOS LXC on PVE running Forgejo, the homelab's git forge. The container is
`module "forge"` in `terraform/pve-forge.tf`, and the service is
`modules/services/forgejo`, using the nixpkgs module on a local PostgreSQL.

The web UI is `https://git.shaneplunkett.com`, through ingress. SSH clones
go straight to the host over the tailnet, as
`forgejo@forge:<owner>/<repo>.git`.

## Signing in

Sign-in goes through Pocket ID, using the `forgejo` client. The first sign-in
creates the account, named from the `preferred_username` claim, and members
of `forgejo_admins` become admins. There's no registration form.

`forgejo-oidc.service` creates the `pocket-id` auth source, or updates it,
whenever the service changes, so the Nix module is the place to change it.
Edits under Site Administration, Authentication Sources get overwritten on
the next deploy that touches it.

## Getting back in

`forgejo-admin` on the host runs `forgejo admin` as the service user, with
the right paths set. If Pocket ID is down, make a local admin and sign in
with the password it prints:

```sh
ssh root@forge forgejo-admin user create --admin --username <name> --email <email> --random-password
```

## Backups and restores

The backup's `prepare` step dumps the database to `/var/backup/forgejo` with
`pg_dump`, and restic backs that up along with `/var/lib/forgejo`: the
repositories, LFS objects, attachments, and the secrets Forgejo generated for
itself under `custom/conf`. A restore needs both halves.

To restore:

```sh
ssh root@forge
restic-homelab restore latest --target /root/restore \
  --include /var/lib/forgejo --include /var/backup/forgejo
systemctl stop forgejo
rm -rf /var/lib/forgejo
cp -a /root/restore/var/lib/forgejo /var/lib/
runuser -u postgres -- dropdb forgejo
runuser -u postgres -- createdb -O forgejo forgejo
runuser -u postgres -- pg_restore --no-owner --role=forgejo -d forgejo \
  /root/restore/var/backup/forgejo/forgejo.dump
systemctl start forgejo
```

## Gotchas

- **SSH doesn't go through ingress.** `git.shaneplunkett.com` resolves to
  the ingress host, which only proxies HTTP, so `SSH_DOMAIN` is the tailnet
  name `forge` instead.
- **The auth source's name is in the callback URL,**
  `/user/oauth2/pocket-id/callback`. Renaming it breaks sign-in until the
  Pocket ID client's callback is changed to match.
- **The client secret is on a command line.** `forgejo admin auth` only
  takes it as a flag, so it's briefly visible in the process list on forge
  while the auth source is set.
- **It runs the LTS release,** the nixpkgs default. Forgejo migrates its
  database forward on upgrade and can't go back, so moving to the latest
  release is a one-way choice.
