# Builder

NixOS LXC on PVE that runs the Forgejo runner for the forge. The container
is `module "builder"` in `terraform/pve-builder.tf`, and the service is
`modules/services/forgejo-runner`. It keeps no state worth backing up, so a
dead builder is rebuilt from code.

## How jobs run

A job with `runs-on: nix` runs straight on the host, not in a container, so
the Nix store stays warm between runs and a second build is mostly cached.
The host has Nix, git, colmena, and node for JavaScript actions like
`actions/checkout`. Anything else a job needs goes in `hostPackages`, or
comes from `nix shell` inside the job. Old store paths are collected weekly.

## Deploying

The deploy workflow runs `colmena apply --on @deploy-on-merge` on each push
to `main`. Its concurrency group queues deploys instead of cancelling them,
which is what Forgejo does by default for pushes. The builder's SSH key is an
authorised root key on every host, and its SSH config maps each host's name
to its LAN address from the hive, because the hosts don't use Tailscale's
DNS. It trusts each host by the key in `modules/agenix/host-keys.nix`.

## Registration

The forge and the builder share the `forgejo-runner-secret` secret, 40 hex
characters. `forgejo-runner-register` on the forge registers the runner with
it on every boot, which is idempotent. The first 16 characters identify the
runner, and its UUID in the Nix module is those characters' bytes as hex.

To replace the secret, from `modules/agenix`:

```sh
head -c 20 /dev/urandom | od -An -tx1 | tr -d ' \n' | rbw edit forgejo-runner-secret
printf '%s' "$(rbw get forgejo-runner-secret)" | agenix -e forgejo-runner-secret.age
printf '%s' "$(rbw get forgejo-runner-secret | head -c 16)" | od -An -tx1 | tr -d ' \n' \
  | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/'
```

The last command prints the new UUID for the module. Deploy the forge, then
the builder.

## Fetching other repos

The forge needs a sign-in to see anything, and a job's own token only reaches
the repo it's running for. So flake inputs from other forge repos, like
`vex-brain`, come over SSH with the builder's own key, `builder-ssh-key`.
The runner loads it as a credential, and the host's SSH config uses it for
`forge`. It's added to each repo the builder fetches as a read-only deploy
key. To print the public half for a new repo:

```sh
ssh root@builder ssh-keygen -y -f /run/agenix/builder-ssh-key
```

## Gotchas

- **`rbw add` and `rbw edit` read from stdin** when it isn't a terminal, and
  only the first line becomes the password. A multi-line value like an SSH
  key can't live in Bitwarden that way, so `builder-ssh-key` exists only in
  agenix. If it's lost, make a new one and replace the deploy keys.
