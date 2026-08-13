# Issue tracker: Linear

Issues and PRDs for this repo live in Linear — workspace `metrokitten`, team `SHA` (Shane). Use the `linear` CLI for all operations. Authentication is managed by the Nix wrapper (Bitwarden `linear-api-key`); verify with `linear auth whoami`, never `auth login`/`--api-key`.

## Conventions

- **Create an issue**: `linear issue create --team SHA --title "..." --description-file <file>`. Always write multi-line descriptions to a temp file and pass `--description-file` — inline `--description` mangles markdown.
- **Read an issue**: `linear issue view SHA-<n>` (add `--comments` for discussion).
- **List issues**: `linear issue list --team SHA --sort manual`.
- **Comment on an issue**: `linear issue comment add SHA-<n> --body-file <file>` (`--body` only for one-liners).
- **Apply / remove labels**: `linear issue update SHA-<n> --label "..."`. Create missing labels first with `linear label create --team SHA --name "..."`.
- **Close**: comment the resolution, then `linear issue update SHA-<n> --state Done` (check state names with `linear team states`).
- **Projects**: group related work with `linear project create --team SHA --name "..."`, then pass `--project` on `issue create`.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Linear is not the PR surface for this repo; GitHub PRs are handled with `gh` independently of triage.)_

## When a skill says "publish to the issue tracker"

Create a Linear issue on team `SHA` (in the relevant project if one exists). Express blocking edges with native relations: `linear issue relation add SHA-<child> blocked-by SHA-<blocker>` — publish blockers first so identifiers exist.

## When a skill says "fetch the relevant ticket"

Run `linear issue view SHA-<n> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a Linear **project** with issues as tickets.

- **Map**: a Linear project holding the Notes / Decisions-so-far / Fog body in its description (`linear project create --team SHA`), or a single issue labelled `wayfinder:map` for small efforts.
- **Child ticket**: an issue in the map project, labelled `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: Linear's **native relations** — `linear issue relation add SHA-<child> blocked-by SHA-<blocker>`; inspect with `linear issue relation list SHA-<n>`. A ticket is unblocked when every blocker is done.
- **Frontier query**: `linear issue list --team SHA --sort manual` scoped to the project, drop any with an open blocker (`linear issue relation list`) or an assignee; first in project order wins.
- **Claim**: `linear issue update SHA-<n> --assignee me` — the session's first write.
- **Resolve**: comment the answer, move the issue to Done, then append a context pointer to the map's Decisions-so-far.
