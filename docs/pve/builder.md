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

## Updates

The update workflow runs weekly, or from the Actions tab with Run workflow.
It runs `nix flake update`, builds every host, pushes the result to
`update/flake-lock` as `forge-bot`, and opens a pull request that says
whether the build passed. It also builds every host from `main` first, so the
pull request can list each host's package changes from
`nix store diff-closures`, leaving out changes that are only in size. That
list can't show a source-only input like `vex-brain`, which has no version,
so the pull request also lists each moved input: a compare link for GitHub
inputs, and the new commits for inputs on the forge. Only then does it ask `metrokitten` to review,
which pings Discord, so the ping always comes with the build's result. If
last week's pull request is still open, it updates that one instead. Merging
it deploys like any other change.

`forge-bot` is a plain forge account with Write access to the repo. Its token
is `forge-bot-token`, in Bitwarden and agenix, and the runner loads it as a
credential. A pull request can't ask its own author for a review, which is why
the updates come from a bot and not from your account.

## Renovate

Renovate runs on the builder every Sunday morning, as `forge-bot`, for the
pins a flake update doesn't touch: container images in Nix modules, flake
inputs pinned to a GitHub tag, the `npx` packages in the dev shell, and
Terraform providers. Each update is its own pull request asking
`metrokitten` to review, which pings Discord. The repo's rules are in
`renovate.json`, and its Nix manager is off, because the update workflow owns
`flake.lock`.

It finds repos by itself: any repo where `forge-bot` is a collaborator gets
an onboarding pull request first, unless it already has a `renovate.json`.
`renovate-github-token` is a read-only GitHub token, because GitHub refuses
to list tags and releases without one. To run it now:

```sh
ssh root@builder systemctl start renovate
```

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
- **Registering without `--keep-labels` wipes the runner's labels.**
  `forgejo-runner-register` re-runs whenever Forgejo restarts, and the
  runner only declares its labels when it starts itself. Without the flag,
  every forge restart left the runner online with no labels, and jobs waited
  for a runner with `nix` that never came.
