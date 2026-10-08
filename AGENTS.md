## Working in this repo

Read `README.md` for how the repo fits together.

- **Nix:** check changes with `colmena build --on <host>` and `git add` new
  files first (flakes ignore untracked files). Don't add comments to Nix code;
  it should read for itself.
- **Secrets:** pipe values from rbw straight into `agenix -e`, and never print
  a secret or token. Only show names, lengths or recipient counts.
- **Monitoring:** the Grafana MCP is read-only. Use it to investigate
  (Prometheus and Loki), then report. Never remediate on its findings alone.
- **Changes:** land every change through a pull request on the forge
  (`origin`; GitHub is a mirror of it). Commit on a branch and file it with
  the `file-pr` skill, which opens it as Vex and asks Shane to review. Done is
  a green build check, plus a Terraform plan comment showing what you expect
  when `terraform/` changed. Shane merges: merging deploys every host and
  applies Terraform.
- **Docs:** keep state out of them (IPs, versions, sizes, what's deployed
  where). If the code explains it, it doesn't need a doc. Docs hold the how,
  the why, and the gotchas.

## Agent skills

### Issue tracker

Issues and PRDs live in Linear (workspace `metrokitten`, team `SHA`), managed via the Linear MCP by default, with the `linear` CLI as fallback.
See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default triage vocabulary.
See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo.
See `docs/agents/domain.md`.

## Cloudflare

Use the `cloudflare` MCP server first, then `cf` from the dev shell. Wrangler is only for Workers and Pages.
See `docs/cloudflare/README.md`.
