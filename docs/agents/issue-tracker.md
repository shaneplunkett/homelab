# Issue tracker: Linear

Issues and PRDs for this repo live in Linear — workspace `metrokitten`, team `SHA` (Shane). **Use the Linear MCP server's tools by default** (`list_issues`, `get_issue`, `save_issue`, `save_comment`, `save_project`, …). **Fall back to the `linear` CLI** when no Linear MCP is connected, when the connected MCP points at a different workspace (check with `get_workspace` — it must say `metrokitten`), or when the MCP lacks the operation (e.g. issue relations).

CLI authentication is managed by the Nix wrapper (Bitwarden `linear-api-key`); verify with `linear auth whoami`, never `auth login`/`--api-key`.

## Conventions

Each operation lists the MCP-first way, then the CLI fallback.

- **Create an issue**: `save_issue` with team `SHA`, real newlines in markdown (no `\n` escapes). CLI: `linear issue create --team SHA --title "..." --description-file <file>` — always write multi-line descriptions to a temp file and pass `--description-file`; inline `--description` mangles markdown.
- **Read an issue**: `get_issue` with `SHA-<n>` (plus `list_comments` for discussion). CLI: `linear issue view SHA-<n> --comments`.
- **List issues**: `list_issues` filtered to team `SHA` / the project. CLI: `linear issue list --team SHA --sort manual`.
- **Comment on an issue**: `save_comment`. CLI: `linear issue comment add SHA-<n> --body-file <file>` (`--body` only for one-liners).
- **Apply / remove labels**: `save_issue` with labels; create missing labels first with `create_issue_label`. CLI: `linear issue update SHA-<n> --label "..."` / `linear label create --team SHA --name "..."`.
- **Close**: comment the resolution, then set the state to Done via `save_issue` (look up state IDs with `list_issue_statuses`). CLI: `linear issue update SHA-<n> --state Done` (check names with `linear team states`).
- **Projects**: group related work with `save_project` on team `SHA`, then reference the project on `save_issue`. CLI: `linear project create --team SHA --name "..."`, then `--project` on `issue create`.
- **Issue relations (blocked-by etc.)**: CLI only — `linear issue relation add SHA-<child> blocked-by SHA-<blocker>`; inspect with `linear issue relation list SHA-<n>`.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Linear is not the PR surface for this repo; GitHub PRs are handled with `gh` independently of triage.)_

## When a skill says "publish to the issue tracker"

Create a Linear issue on team `SHA` (in the relevant project if one exists). Express blocking edges with native relations (CLI): `linear issue relation add SHA-<child> blocked-by SHA-<blocker>` — publish blockers first so identifiers exist.

## When a skill says "fetch the relevant ticket"

`get_issue` + `list_comments` for `SHA-<n>` (CLI: `linear issue view SHA-<n> --comments`).

## Wayfinding operations

Used by `/wayfinder`. The **map** is a Linear **project** with issues as tickets.

- **Map**: a Linear project holding the Notes / Decisions-so-far / Fog body in its description (`save_project` on team `SHA`; CLI: `linear project create --team SHA`), or a single issue labelled `wayfinder:map` for small efforts.
- **Child ticket**: an issue in the map project, labelled `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: Linear's **native relations** — CLI only: `linear issue relation add SHA-<child> blocked-by SHA-<blocker>`; inspect with `linear issue relation list SHA-<n>`. A ticket is unblocked when every blocker is done.
- **Frontier query**: `list_issues` scoped to the project (CLI: `linear issue list --team SHA --sort manual`), drop any with an open blocker (`linear issue relation list`) or an assignee; first in project order wins.
- **Claim**: assign the issue to yourself via `save_issue` (CLI: `linear issue update SHA-<n> --assignee me`) — the session's first write.
- **Resolve**: comment the answer, move the issue to Done, then append a context pointer to the map's Decisions-so-far.
