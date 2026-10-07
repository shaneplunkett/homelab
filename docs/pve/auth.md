# Auth

NixOS LXC on PVE running Pocket ID, the homelab's single sign-on. It's an
OIDC provider that only does passkeys, so there are no passwords anywhere.
The container is `module "auth"` in `terraform/pve-auth.tf`, and the service
is `modules/services/pocket-id`, using the nixpkgs module.

The admin UI is `https://auth.shaneplunkett.com`. Pocket ID publishes its
endpoints at `/.well-known/openid-configuration`, and most apps only need
that URL or the three endpoints in it.

## Adding an app

Check Pocket ID's [client examples](https://pocket-id.org/docs/client-examples)
first. They cover a lot of apps, including Proxmox and Unraid, and list the
callback URL and scopes each one wants.

1. In Pocket ID, open OIDC Clients and add one:
   - The callback URL comes from the app's docs or the client example.
   - Turn PKCE on if the app supports it.
   - Turn Skip Consent Screen on. These are all our own apps.
   - Leave Public Client, Re-Authentication and Pushed Authorization
     Requests off.
   - Set Client ID to the app's name, like `grafana`, so the Nix config
     can name it instead of needing a random UUID.
2. Saving doesn't show a secret. Open the client again, add one under Client
   secrets, and save it in Bitwarden as `<app>-oidc-client-secret`. Pocket ID
   only shows it once.
3. Add `<app>-oidc-client-secret.age` to `modules/agenix/agenix-rules.nix`
   with the app's host as a recipient, then from `modules/agenix`:

   ```sh
   printf '%s' "$(rbw get <app>-oidc-client-secret)" | agenix -e <app>-oidc-client-secret.age
   ```

4. Point the app at Pocket ID in its module, reading the secret from
   `config.age.secrets.<app>-oidc-client-secret.path`.
   `modules/services/grafana` is the worked example.
5. `colmena apply --on <host>`, then sign in from the app's login page.

### Roles

Pocket ID sends a `groups` claim when the app asks for the `groups` scope.
Map roles from group names rather than emails. Grafana makes members of
`grafana_admins` an Admin and everyone else a Viewer. Use the same
`<app>_admins` pattern for the next app.

Groups live in Pocket ID under User Groups. The group's name is what goes in
the claim, not its display name.

### Proxmox

The realm is cluster-wide, and Terraform can't manage it. The Terraform
token's role has no `Realm.Allocate` or `Permissions.Modify`, and adding
`Permissions.Modify` would let it grant itself anything. So the realm was
made once by hand. To make it again, from this repo:

```sh
printf '%s\n' "$(rbw get proxmox-oidc-client-secret)" | ssh shane@<pve> 'sudo bash -c '\''
read -r key
pveum realm add pocket-id --type openid --comment "Pocket ID" \
  --issuer-url https://auth.shaneplunkett.com --client-id proxmox --client-key "$key" \
  --scopes "email profile groups" --username-claim username \
  --autocreate 1 --groups-claim groups --groups-overwrite 1 --default 1
pveum group add proxmox_admins-pocket-id
pveum acl modify / --groups proxmox_admins-pocket-id --roles Administrator
'\'''
```

The secret goes in on stdin so it stays out of sudo's log.

- **Proxmox renames groups.** It adds the realm to each group from the claim,
  so `proxmox_admins` in Pocket ID becomes `proxmox_admins-pocket-id`. It
  only syncs groups that already exist in Proxmox, and the ACL is on that
  group.
- **Don't add `openid` to the scopes.** Proxmox adds it itself.
- **The callback is the bare origin,** `https://proxmox.shaneplunkett.com`.
  Signing in at a node's own address needs that origin added to the client.
- **The nodes need to resolve `auth.shaneplunkett.com`.** Proxmox fetches
  tokens itself, and the router doesn't know the homelab's names. Each node's
  DNS is in `terraform/proxmox-dns.tf`: Blocky on dns1 and dns2 first, the
  router last as a fallback.
- `shane@pam` is the way in when Pocket ID is down.

### Unraid

Unraid (7.2 or later) keeps OIDC in its own UI, under Settings, Management
Access, API, OIDC. It saves to
`/boot/config/plugins/dynamix.my.servers/configs/oidc.json` on the flash
drive.

- The callback is `https://unraid.shaneplunkett.com/graphql/api/auth/oidc/callback`.
- The issuer URL has no trailing slash.
- Add `groups` to the scopes, and use Advanced authorization with one rule,
  `groups` contains `unraid_admins`. Every OIDC login signs in as root, so
  this rule is the only thing deciding who gets in.
- The root password still works when Pocket ID is down.

### Apps without OIDC

The arr apps, SABnzbd and Deluge have no OIDC login. The plan for those is
oauth2-proxy on the ingress host. nixpkgs wires it into nginx with
`services.oauth2-proxy.nginx.virtualHosts`, so each protected route becomes
one line. Phone apps that use the arr APIs will need their API paths left
outside it.

## Getting back in

**If Pocket ID is down,** every app keeps its own local admin login. Keep
those in Bitwarden and don't disable the login form in any app.

**If the passkey is lost,** make a one-time sign-in link on the host:

```sh
ssh root@auth pocket-id-recover <username or email>
```

It prints a link that works once within the hour. Sign in with it and
register a new passkey.

## Backups and restores

The backup's `prepare` step copies the SQLite database to
`/var/lib/pocket-id/dumps` with `.backup`, and restic backs that up along
with the rest of `/var/lib/pocket-id`. The live database files are excluded.

Pocket ID encrypts its signing keys with the `pocket-id-encryption-key`
secret, so a restore is useless without it. The key is in agenix and in
Bitwarden under the same name.

To restore:

```sh
ssh root@auth
restic-homelab restore latest --target /root/restore --include /var/lib/pocket-id
systemctl stop pocket-id
rm /var/lib/pocket-id/data/pocket-id.db*
install -o pocket-id -g pocket-id -m 0600 \
  /root/restore/var/lib/pocket-id/dumps/pocket-id.db /var/lib/pocket-id/data/pocket-id.db
systemctl start pocket-id
```

## Gotchas

- **Passkeys need HTTPS on the real name.** A passkey belongs to
  `auth.shaneplunkett.com`, so the UI only works through ingress. The LAN
  address and port load, but sign-in fails there.
- **Don't change `APP_URL` casually.** Every app's config and every passkey
  is tied to it. Changing the hostname means registering passkeys again.
- **`TRUST_PROXY` is on**, because nginx terminates TLS. The nixpkgs option
  only takes a boolean, so Pocket ID trusts forwarded headers from anywhere.
  Something on the LAN talking to the port directly could fake the client IP
  in Pocket ID's audit log, but nothing more.
