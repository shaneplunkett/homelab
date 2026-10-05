# Cloudflare

Cloudflare holds `shaneplunkett.com` and `shaneplunkett.dev` (Registrar and DNS), the Red Book Pages site, Cloudflare Access for `vex.shaneplunkett.dev` and the `mcphub` tunnel.

## Tooling

Everything comes from the repo's `flake.nix` via direnv (`use flake` in `.envrc`).

- **Cloudflare MCP** (`.mcp.json`): the Code Mode server at `https://mcp.cloudflare.com/mcp`. It covers the whole API: DNS, DNSSEC, Registrar, Access, tunnels, Pages, Workers and analytics.
- **`cf`**: the official Cloudflare CLI (beta), a scriptable fallback for the same API. It isn't in nixpkgs yet, so the flake runs a pinned npm release through `npx`.
- **`wrangler`**: Workers and Pages projects only. It has no DNS, zone, Registrar or Access commands.
- **`cloudflared`**: tunnel runtime and management.
- **`dig`, `doggo`**: checking public DNS from outside the Technitium split view.

Agent skills from `cloudflare/skills` (`cloudflare`, `cloudflare-one`, `wrangler`, `workers-best-practices`) are pinned in `skills-lock.json`.

## Credentials

One account-owned API token (`cfat_` prefix), stored in rbw as `homelab_cf_token`. The password is the token and the username is the account ID.

- `.envrc` exports them as `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` for `cf`, `wrangler` and Terraform.
- The MCP server reads the token through `tools/cloudflare/mcp-headers.sh`, so it never sits in a config file.

Older docs say account tokens can't use the Registrar, but on 5 October 2026 `GET /accounts/{id}/registrar/registrations/{domain}` worked with this token. Don't add client IP filtering, since the MCP server rejects IP-filtered tokens.

Token permissions:

| Scope | Permission | Level |
|-------|------------|-------|
| Account | Account Settings | Read |
| Account | Account Analytics | Read |
| Account | Access: Apps and Policies | Edit |
| Account | Cloudflare Tunnel | Edit |
| Account | Pages | Write |
| Account | Workers | Editor |
| Account | Registrar Domains | Admin |
| Zone | Zone | Read |
| Zone | Zone Settings | Edit |
| Zone | DNS | Edit |
| Zone | Analytics | Read |

Account and Zone permissions need separate policies. The Zone ones only take effect in a policy whose resources are the account's zones (`{"com.cloudflare.api.account.<id>": {"com.cloudflare.api.account.zone.*": "*"}}`), and putting them under an "Entire Account" policy silently does nothing. Saving the token in the dashboard dropped the zone policy on 5 October 2026, so change this token's permissions through the API (`PUT /accounts/{id}/tokens/{token_id}`) rather than the dashboard. DNSSEC has no permission of its own; it needs DNS Edit.

## Gotchas

- The local Technitium serves its own `shaneplunkett.com` zone, so LAN lookups don't match the public answer. Ask public DNS instead, e.g. `dig @1.1.1.1` or `doggo @https://cloudflare-dns.com/dns-query`.
- The `cf` CLI is beta. Non-interactive deletes without `--force` print `Aborted.` and exit 0, so check the result rather than the exit code.
- The legacy Registrar `domains` list endpoint reached end of life on 27 September 2026. Use `GET /accounts/{id}/registrar/registrations/{domain}` for `auto_renew` and `expires_at`.
- If the MCP server ever fails auth (for example, rbw was locked), Claude Code caches it as needing auth and stops connecting, even after the token works again. Remove the `cloudflare` key from `~/.claude/mcp-needs-auth-cache.json` and start a new session.
- T3 Code runs Claude with `CLAUDE_CONFIG_DIR=~/.claude`, so folder trust lives in `~/.claude/.claude.json`, not `~/.claude.json`. The `headersHelper` only runs once that file has `hasTrustDialogAccepted: true` for the repo.
