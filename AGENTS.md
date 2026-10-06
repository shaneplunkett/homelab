## Working in this repo

Read `README.md` for how the repo fits together.

- **Nix:** check changes with `colmena build --on <host>` and `git add` new
  files first (flakes ignore untracked files). Don't add comments to Nix code;
  it should read for itself.
- **Secrets:** pipe values from rbw straight into `agenix -e`, and never print
  a secret or token. Only show names, lengths or recipient counts.
- **Monitoring:** the Grafana MCP is read-only. Use it to investigate
  (Prometheus and Loki), then report. Never remediate on its findings alone.
- **Docs:** keep state out of them (IPs, versions, sizes, what's deployed
  where). If the code explains it, it doesn't need a doc. Docs hold the how,
  the why, and the gotchas.
- **Legacy Alpine LXCs:** don't add new support for them. They get migrated
  to Nix instead.

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
