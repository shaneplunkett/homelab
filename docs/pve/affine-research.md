# AFFiNE — personal knowledge platform evaluation

**Research date:** 2026-08-24
**Version evaluated:** v0.27.4 (released 18 August 2026)
**Scope:** desk research against primary sources (affine.pro, docs.affine.pro,
the GitHub repo/releases/issues/discussions, licence files in the source) plus
clearly-labelled community reports for pain points. No test deployment was
made. Evaluated as a personal Notion alternative for this homelab (pve,
Docker-capable, existing reverse proxy + backup patterns).

## TL;DR

- AFFiNE is a **local-first, open-core "Notion + Miro" workspace** — block-based
  docs and an infinite whiteboard (edgeless mode) sharing one data model, built
  on the Yjs CRDT via the BlockSuite editor and the y-octo Rust engine.
  [README](https://github.com/toeverything/AFFiNE)
- **Self-hosting is officially supported and Docker-compose-first**: one
  `ghcr.io/toeverything/affine` container plus **Postgres (pgvector) and Redis
  (both mandatory)**, a migration job, admin panel at `/admin`, email +
  Google/GitHub/generic **OIDC** auth, nginx/caddy examples in the docs.
  Recommended host: 4 cores / 2–4 GB RAM.
  [Self-host docs](https://docs.affine.pro/self-host-affine),
  [Requirements](https://docs.affine.pro/self-host-affine/install/requirements)
- **Licence is mixed**: everything except the backend is MIT; the server
  (`packages/backend`) is under a source-available "Enterprise Edition" licence
  with CE parts under MPL-2.0. Self-hosted workspaces get Pro-level quota for
  free (10 members, 100 GB); more seats are a paid team licence. For one person
  none of the gates bite.
  [LICENSE](https://github.com/toeverything/AFFiNE/blob/canary/LICENSE),
  [EE licence](https://github.com/toeverything/AFFiNE/blob/canary/packages/backend/server/LICENSE),
  [maintainer on quotas](https://github.com/toeverything/AFFiNE/issues/6641)
- **AI works self-hosted** via BYOK (bring your own key): OpenAI, Anthropic,
  Gemini and FAL keys per workspace, experimental since 0.27.
  [Self-host AI docs](https://docs.affine.pro/self-host-affine/administer/ai)
- Healthy momentum: ~71.8k stars, 253 contributors, stable releases roughly
  monthly through 2025–2026 (0.20 Feb 2025 → 0.27.4 Aug 2026), Notion/Obsidian/
  Bear/OneNote importers landed in 0.27 (GitHub API,
  [releases](https://github.com/toeverything/AFFiNE/releases)). Backed by
  Toeverything Pte Ltd (Singapore); third-party trackers report ~US$18M raised.
- The catches: **databases are far weaker than Notion's** (no relations or
  rollups), **mobile apps are not local-first** (dead without the server),
  export is per-doc with known edgeless-export gaps, data lives in binary
  CRDT/SQLite rather than plain files, and minor-version upgrades carry real
  breaking changes (0.23 image rename, 0.27 env-vars → `config.json`,
  client/server version coupling).
- **Verdict: worth a trial deployment.** The doc+whiteboard fusion, offline
  desktop, self-host story and BYOK AI beat Notion for a privacy-minded solo
  homelab user. If the actual want is Notion-grade databases, AFFiNE will
  disappoint — that gap is structural, not a missing patch.

## 1. Feature set

### Docs (block editor)

The editor is [BlockSuite](https://blocksuite.io), AFFiNE's own open-source
block editor framework — "everything is a block", with rich text, linked pages,
embeds, code blocks, and (improved in 0.27) LaTeX, Mermaid and Typst rendering
([README](https://github.com/toeverything/AFFiNE),
[v0.27.0 release notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).

### Edgeless / whiteboard mode

The headline feature: every doc can flip into an infinite canvas holding rich
text, sticky notes, shapes, connectors, embedded web pages, database views,
linked pages and slide frames — the README claims it is "one of the very few"
tools where any block can live on the canvas
([README](https://github.com/toeverything/AFFiNE)). 0.27 shipped edgeless
rendering/memory/touch improvements
([release notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
Notion has nothing equivalent.

### Databases / tables — the honest comparison with Notion

Multi-view database blocks exist: table and kanban views, custom fields, plus a
**Calendar view added in 0.27.0**
([release notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
What they do **not** have is Notion's relational layer — no relations between
databases, no rollups, no formulas, no linked/filtered database views across
pages. Third-party comparisons say the same
([fabric.so comparison](https://fabric.so/comparison/affine-vs-notion)), and the
project's own open feature requests confirm the gaps from the inside: CSV
import into databases
([#14966](https://github.com/toeverything/AFFiNE/issues/14966)) and basic table
enhancements like cell merging
([#14214](https://github.com/toeverything/AFFiNE/issues/14214)) are still asks.
If the Notion use case is databases-as-apps (trackers with relations and
rollups), AFFiNE is not there and there's no roadmap date for it.

### Journals, templates, calendar

- Journals (daily notes) are built in; the calendar integration can create docs
  linked to the day's journal from calendar events, and 0.27 improved CalDAV
  sync ([calendar docs](https://docs.affine.pro/features/calendar-integrations),
  [release notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
- An official template gallery exists (planners, Cornell notes, reading logs,
  etc.) ([templates](https://affine.pro/templates),
  [README](https://github.com/toeverything/AFFiNE)).

### AI — and yes, it works self-hosted

- Cloud: "AFFiNE AI" is a paid add-on — writing/rewriting, outline→slides,
  article→mind-map, image generation ([affine.pro/ai](https://affine.pro/ai),
  [pricing](https://affine.pro/pricing)).
- Self-hosted: **BYOK** since 0.27 (flagged experimental). Enable
  `copilot.byok` in `config.json`, then add per-workspace keys under Settings →
  Integrations → AI BYOK. Supported providers: **OpenAI, Anthropic, Gemini,
  FAL**; OpenAI-compatible custom endpoints (e.g. a local proxy) can be allowed
  server-side via `allowCustomEndpoint`. Workspace AI indexing needs pgvector
  (the official compose already uses it) plus the indexer, and
  transcription/indexing specifically want a server-stored Gemini key
  ([self-host AI docs](https://docs.affine.pro/self-host-affine/administer/ai),
  [discussion #11722](https://github.com/toeverything/AFFiNE/discussions/11722)).
  Native Ollama support is a community request, not a feature
  ([#13525](https://github.com/toeverything/AFFiNE/issues/13525)).

### Web clipper

Official browser extension on the Chrome Web Store (4.7★) that captures pages
into the workspace
([AFFiNE Web Clipper](https://chromewebstore.google.com/detail/affine-web-clipper/mpbbkmbdpleomiogkbkkpfoljjpahmoi)).

### Mobile apps

Free iOS and Android apps exist and sync with AFFiNE Cloud **or a self-hosted
server** ([download page](https://affine.pro/download)). State of play: usable
but the weakest platform — see pain points §9. Critically, the mobile apps are
**not local-first**: with a self-hosted server down, the app loads nothing
([#13285, open feature request](https://github.com/toeverything/AFFiNE/issues/13285)).
0.27.x notes show ongoing Android input/keyboard fixes
([v0.27.4](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.4)).

### Desktop apps

Windows, macOS, Linux (AppImage / .deb / Flatpak). The desktop app is genuinely
local-first: workspaces are stored on-device and fully readable/editable
offline, with sync only when signed in to a cloud (or self-hosted) server
([download FAQ](https://affine.pro/download)). Desktop clients connect to a
self-hosted server from the workspace list panel
([after-installation docs](https://docs.affine.pro/self-host-affine/install/after-installation)).
macOS desktop also has meeting recording/transcription
([meeting docs](https://docs.affine.pro/features/meeting-macos)), and an MCP
server surfaced in 0.27-era builds (still rough —
[#15112](https://github.com/toeverything/AFFiNE/issues/15112),
[#14582](https://github.com/toeverything/AFFiNE/issues/14582)).

## 2. Self-hosting

### Stack

The official method is Docker Compose
([self-host docs](https://docs.affine.pro/self-host-affine),
[reference compose](https://docs.affine.pro/self-host-affine/references/docker-compose-yml)):

| Service | Image | Notes |
| --- | --- | --- |
| affine | `ghcr.io/toeverything/affine:stable` | Web app + API + sync, port **3010**; volumes `./data/storage` (blobs) and `./config` |
| affine_migration | same image | One-shot `self-host-predeploy.js` job before the server starts |
| postgres | `pgvector/pgvector:pg16` | The only supported database; pgvector needed for AI indexing |
| redis | `redis` | **Mandatory** — cache, background tasks, "core of sync system" |

The compose file ships attached to each GitHub release
([upgrade docs](https://docs.affine.pro/self-host-affine/install/upgrade)).

### Resource footprint

Official requirements ([docs](https://docs.affine.pro/self-host-affine/install/requirements)):
~1.5 GB disk for the install; ~100 MB Postgres growth per 1k docs and ~10 GB
blob growth per 1k blobs; **2 GB RAM for basic use, 4 GB if docs exceed ~10k
words** (merging a doc with 10k modifications can peak at 1 GB); **4 CPU cores
recommended**. Prometheus monitoring is optional and adds ~200 MB. That is
noticeably heavier than this repo's usual single-container LXCs — plan a
4 GB / 4-core VM or LXC, not a 512 MB Alpine box.

### Admin, auth, users

- First visit to `http://host:3010/admin` creates the admin account; the admin
  panel handles settings, OAuth, user import/reset/ban
  ([after-installation](https://docs.affine.pro/self-host-affine/install/after-installation)).
- Auth: email/password, plus **Google, GitHub, and generic OIDC** configured in
  Admin Panel → Settings → OAuth (`redirect_uri` = `/oauth/callback`)
  ([OAuth docs](https://docs.affine.pro/self-host-affine/administer/oauth-2-0)).
  Fits an existing SSO/IdP if one ever lands in this homelab.

### Reverse proxy

Documented nginx and Caddy examples; requirements are ordinary — **websocket
pass-through is essential** (sync runs over websockets) and
`client_max_body_size` must cover uploads
([domain and HTTPS docs](https://docs.affine.pro/self-host-affine/administer/domain-and-https)).
Sits behind the existing NPM wildcard setup without drama; set the external URL
in config so share links are correct.

### Upgrades — read the notes every time

- Process: `wget` the release's `docker-compose.yml`, `docker compose pull`,
  `up -d` ([upgrade docs](https://docs.affine.pro/self-host-affine/install/upgrade)).
- Breaking changes land at minor bumps and they're real:
  - 0.23.0 renamed the image `affine-graphql` → `affine` (manual compose edit)
    ([upgrade docs](https://docs.affine.pro/self-host-affine/install/upgrade)).
  - 0.27.0 demoted environment variables — config moves to `config.json`, and
    some env vars stopped working
    ([v0.27.0 notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
  - **Client/server versions are coupled**: 0.27 clients need a ≥0.27 server;
    a 0.27 server only accepts ≥0.26 clients. Desktop/mobile auto-update can
    therefore force a server upgrade
    ([v0.27.0 notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
  - BYOK "may need to be reconfigured when upgrading versions"
    ([v0.27.4 notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.4)).
- Pin a version tag rather than `:stable`, and back up Postgres + the blob
  volume before every bump (the docs put backup/restore before production use:
  [self-host overview](https://docs.affine.pro/self-host-affine)).

### Homelab suitability call

Concretely: this is a **three-service stateful stack** (app + Postgres +
Redis) with a 4 GB RAM recommendation, monthly-ish upgrades that occasionally
break config, and backups that mean `pg_dump` + blob directory, not one volume
copy. Entirely doable with this repo's compose-in-LXC pattern, but it's the
heaviest knowledge app in the fleet by some margin — closer to running Outline
or Nextcloud than to Technitium.

## 3. Local-first architecture

- **CRDT foundation:** documents are Yjs CRDTs. The editor layer is
  [BlockSuite](https://github.com/toeverything/BlockSuite); the sync/storage
  engine is [y-octo](https://github.com/y-crdt/y-octo), "a native,
  high-performance, thread-safe YJS CRDT implementation" in Rust, with
  [OctoBase](https://github.com/toeverything/OctoBase) as the local-first data
  engine — all credited in the
  [README's upstreams](https://github.com/toeverything/AFFiNE#upstreams).
- **What offline actually works:** on **desktop**, everything — local
  workspaces never touch a server, and cloud workspaces keep an on-device copy
  you can read and edit offline, syncing when connected
  ([download FAQ](https://affine.pro/download)). In a **browser**, a "local"
  workspace lives in browser storage with no sync at all
  ([maintainer, discussion #14130](https://github.com/toeverything/AFFiNE/discussions/14130)).
  On **mobile**, offline does not work against a self-hosted server —
  server down means no data ([#13285](https://github.com/toeverything/AFFiNE/issues/13285)).
- **How sync works:** clients push CRDT updates over websockets to the server
  (cloud or self-hosted — same code path), which persists doc updates in
  Postgres and blobs on disk/object storage, with Redis coordinating the sync
  and task system
  ([self-host overview](https://docs.affine.pro/self-host-affine),
  [requirements](https://docs.affine.pro/self-host-affine/install/requirements),
  [domain docs on websockets](https://docs.affine.pro/self-host-affine/administer/domain-and-https)).
- **Conflict handling:** CRDT merge semantics — concurrent edits converge
  automatically without manual conflict resolution; that's the point of
  building on Yjs ([README](https://github.com/toeverything/AFFiNE#upstreams)).
  The cost is memory: merging a heavily-edited doc is the documented RAM driver
  ([requirements](https://docs.affine.pro/self-host-affine/install/requirements)).

## 4. Data ownership & export

- **Storage format:** not plain files. Desktop workspaces are SQLite databases
  in the app data directory (e.g.
  `~/Library/Application Support/affine` on macOS), holding binary CRDT state
  ([community answer](https://community.affine.pro),
  community report). Server-side, docs live in Postgres and attachments in the
  blob store ([storage docs](https://docs.affine.pro/self-host-affine/administer/storage)).
  Greppable-Markdown-on-disk this is not — that's Obsidian's trade.
- **Export options:** per-doc export to **Markdown, HTML, PDF and PNG**, plus
  the native `.affine` snapshot format (PDF export added mid-2023:
  [official release note](https://affine.pro/what-is-new/20230620); earlier
  formats: [alpha announcement](https://affine.pro/blog/affine-alpha-is-coming)).
- **Known export limitations (verified current):**
  - Edgeless/whiteboard export is patchy: exporting frames as PNG/SVG is an
    open bug ([#12128](https://github.com/toeverything/AFFiNE/issues/12128)),
    and frames→PPT/PDF is an open request
    ([#13524](https://github.com/toeverything/AFFiNE/issues/13524)).
  - There is still **no automatic/scheduled workspace backup or bulk export**
    in-app — a long-open, well-upvoted issue
    ([#8399](https://github.com/toeverything/AFFiNE/issues/8399)). Self-hosted,
    the honest backup is `pg_dump` + the blob volume.
- **Import from Notion:** supported — export from Notion as **HTML** (with
  subpages) and import
  ([official guide](https://affine.pro/blog/import-your-data-from-notion-into-affine)).
  0.27.0 added native-client importers for **Notion, Obsidian, Bear and
  OneNote** ([release notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
  Community reports (labelled as such): simple pages and tables come across;
  complex Notion setups — relations, rollups, formulas, linked databases —
  don't convert cleanly ([fabric.so](https://fabric.so/comparison/affine-vs-notion)),
  which follows from §1: AFFiNE has nowhere to put them.

## 5. Pricing & licensing

All pricing is **USD** on the official page — no AUD list
([pricing](https://affine.pro/pricing)).

| Plan | Price | Limits |
| --- | --- | --- |
| Free (cloud) | $0 | 10 GB cloud storage, 10 MB max file, ≤3 members/workspace, 7-day version history; unlimited local workspaces/devices/blocks |
| Pro | US$6.75/mo billed annually (~US$7.99 monthly) | 100 GB storage, 100 MB files, ≤10 members, 30-day history |
| Team | US$10/seat/mo | 100 GB + 20 GB/seat, 500 MB files, dynamic seats |
| AFFiNE AI | paid add-on | multimodal copilot across docs/edgeless |

([pricing page](https://affine.pro/pricing); tier details corroborated by
[spotSaaS breakdown](https://www.spotsaas.com/product/affine/pricing) —
community source.)

**Self-hosted split:**

- The self-hosted server is free to run and, per the maintainer, self-hosted
  users are **granted Pro-level quota** (the earlier "Free-plan-on-your-own-
  hardware" limits caused an outcry —
  [#6641](https://github.com/toeverything/AFFiNE/issues/6641)). Practical
  meaning for one person: no gate you'll ever hit.
- **Seats beyond the included quota are paid**: a Team Plan subscription
  (licence-checks against app.affine.pro) or an offline **Installable License**
  for air-gapped deployments
  ([team licence docs](https://docs.affine.pro/self-host-affine/features/team-license)).
- **Licence (from the source, not the marketing):** the root
  [LICENSE](https://github.com/toeverything/AFFiNE/blob/canary/LICENSE) is MIT
  for everything **except** `packages/backend` and `packages/common/native`,
  which fall under the
  [Enterprise Edition licence](https://github.com/toeverything/AFFiNE/blob/canary/packages/backend/server/LICENSE) —
  source-available, production use tied to their subscription terms, with parts
  distributed in the Community Edition under MPL-2.0. So: **MIT editor,
  source-available backend** — the pricing page itself says exactly that
  ([pricing](https://affine.pro/pricing)). The ambiguity of where CE ends and
  EE begins was raised (by BookStack's author, no less) and never crisply
  answered ([discussion #5947](https://github.com/toeverything/AFFiNE/discussions/5947)).
  For personal self-hosting this is a philosophical objection, not a practical
  one; it matters if "OSI-open-source all the way down" is a hard requirement.

## 6. Maturity & community health

- **Repo:** created July 2022; **~71,800 stars, 5,200 forks, 253 contributors,
  ~708 open issues** as of this research (GitHub API).
- **Releases:** rapid and steady. Stable minors roughly every 1–3 months
  through 2025–2026 — 0.20 (Feb 2025), 0.21 (Apr), 0.22 (Jun), 0.23 (Jul),
  0.24 (Aug), 0.25 (Oct), 0.26 (Feb 2026), 0.27 (Jul 2026) — with patch
  releases in between and canary builds every few days; latest stable 0.27.4
  on 18 Aug 2026 ([releases](https://github.com/toeverything/AFFiNE/releases)).
  2026 momentum is real: BYOK AI, database calendar view, four new importers,
  CalDAV, MCP, blob GC all landed in the 0.26–0.27 window.
- **Company:** TOEVERYTHING PTE. LTD., Singapore, founded ~2022
  ([about page](https://affine.pro/about-us)). Funding: third-party trackers
  (community source, not verifiable from primary docs) report **~US$18M across
  two rounds** ([Tracxn profile](https://tracxn.com/d/companies/affine/__Mo6BFrzUISfgrA8pldUKbTH0mEXrtjxwRlYfPIADZqs)).
  Revenue comes from cloud subscriptions, the AI add-on, and
  enterprise/self-host team licences ([pricing](https://affine.pro/pricing),
  [enterprise](https://affine.pro/enterprise)) — a coherent open-core model,
  though a young venture-backed one, so the usual sustainability caveat
  applies. Mitigation: the editor is MIT and data is exportable, so a company
  failure strands the sync server, not the notes.
- Contributor CLA is required for PRs
  ([README](https://github.com/toeverything/AFFiNE#contributing)).

## 7. Honest comparison vs Notion (personal use)

**Where AFFiNE genuinely wins:**

- **Whiteboard + doc fusion.** Notion has no canvas at all; AFFiNE's edgeless
  mode with real blocks on it is the differentiator
  ([README](https://github.com/toeverything/AFFiNE),
  [fabric.so](https://fabric.so/comparison/affine-vs-notion)).
- **Local-first + offline desktop.** Notion is cloud-first with limited offline;
  AFFiNE desktop works fully offline and keeps data on disk
  ([download FAQ](https://affine.pro/download)).
- **Self-hosting.** Notion cannot be self-hosted, full stop. AFFiNE runs on the
  homelab with the same sync/collaboration features as its cloud
  ([self-host docs](https://docs.affine.pro/self-host-affine)).
- **Data control and cost.** Solo self-host: US$0 forever with Pro-level quota
  ([#6641](https://github.com/toeverything/AFFiNE/issues/6641)); BYOK AI at
  provider token prices instead of a per-seat AI subscription
  ([AI docs](https://docs.affine.pro/self-host-affine/administer/ai)).

**Where Notion is still clearly ahead:**

- **Databases.** Relations, rollups, formulas, six view types, linked filtered
  views — AFFiNE has table/kanban/calendar with custom fields and none of the
  relational machinery (§1, [fabric.so](https://fabric.so/comparison/affine-vs-notion)).
- **Integrations & ecosystem.** Notion's public API, thousands of integrations
  and template economy have no AFFiNE counterpart; AFFiNE's API story is a
  nascent MCP server ([#15112](https://github.com/toeverything/AFFiNE/issues/15112)).
- **Mobile.** Notion's apps are mature; AFFiNE's are young, bug-prone and
  server-dependent (§9).
- **Sharing/publishing & polish.** Notion's public pages, granular permissions
  and general fit-and-finish outclass AFFiNE, which still carries editor
  rough edges and performance complaints (§9).

## 8. Brief alternatives check

- **Obsidian** — plain Markdown files on disk, enormous plugin ecosystem, free
  for personal use but **proprietary** (the app isn't open source; only the
  release/plugin repos are public — [GitHub](https://github.com/obsidianmd/obsidian-releases)).
  Best-in-class for pure notes and data longevity (files you can grep and
  restic-back-up), with Canvas for light whiteboarding. No first-party
  self-hosted sync — pay for Obsidian Sync or roll Syncthing/git. If the want
  is "notes that outlive every app", Obsidian beats AFFiNE; if it's
  Notion-style structured docs + shared canvas, it doesn't.
- **Anytype** — local-first, CRDT-based, object/relation data model that is
  actually closer to Notion databases than AFFiNE's. Clients are source-
  available under the "Any Source Available License" (not OSI —
  [GitHub](https://github.com/anyproto/anytype-ts), ~8.7k stars), and the
  any-sync backend can be self-hosted, though it's a more exotic multi-node
  stack than one compose file. Weaker web/publishing story; smaller community.
- **Outline** — polished self-hosted team wiki (Postgres + Redis, like AFFiNE)
  with excellent Markdown editing and search; **BUSL-1.1** licence
  ([GitHub](https://github.com/outline/outline), ~40k stars). It's a wiki, not
  a workspace: no whiteboard, no local-first clients, browser-only. Great for
  documentation, wrong shape for a personal everything-app.
- **SiYuan** — **AGPL-3.0** ([GitHub](https://github.com/siyuan-note/siyuan),
  ~46k stars), block-based, local-first with self-hostable sync, strong
  backlinks/SQL-queryable blocks, genuinely offline mobile apps. Feature-dense
  but the UX is idiosyncratic and the community/docs are Chinese-first; some
  sync features are behind a paid tier. The closest "AFFiNE but AGPL" option.

## 9. Known pain points from real users

All items below are community reports (GitHub issues, forum threads), linked.

1. **Sync reliability on self-host.** A long tail of "connect to remote
   timeout" / sync-not-working threads, usually reverse-proxy websocket or
   external-URL misconfiguration but not always
   ([community thread](https://community.affine.pro/c/community-support/self-hosted-sync-with-cloud-not-working-error-connect-to-remote-timeout),
   [#6298, closed](https://github.com/toeverything/AFFiNE/issues/6298)).
   Users still ask for visible/manual sync control because silent sync failures
   cost data confidence
   ([#15488](https://github.com/toeverything/AFFiNE/issues/15488)).
2. **Performance with large docs/workspaces.** Very high RAM while typing
   ([#15415, Aug 2026](https://github.com/toeverything/AFFiNE/issues/15415)),
   page-mode lag scaling with embedded frames
   ([#14585](https://github.com/toeverything/AFFiNE/issues/14585)), edgeless
   slowdowns on larger boards
   ([#14333](https://github.com/toeverything/AFFiNE/issues/14333)), and an
   open proposal to add virtual rendering
   ([#13616](https://github.com/toeverything/AFFiNE/issues/13616)). Server-side
   memory during doc merges is acknowledged in the official requirements
   ([docs](https://docs.affine.pro/self-host-affine/install/requirements)).
3. **Export fidelity.** Edgeless frame export broken/missing (PNG/SVG bug
   [#12128](https://github.com/toeverything/AFFiNE/issues/12128); PPT/PDF
   request [#13524](https://github.com/toeverything/AFFiNE/issues/13524)); no
   automatic backup/bulk export
   ([#8399](https://github.com/toeverything/AFFiNE/issues/8399)); no raw
   Markdown editing mode
   ([#13565](https://github.com/toeverything/AFFiNE/issues/13565)).
4. **Upgrade breakage.** 0.23's image rename and 0.27's env-var → `config.json`
   migration both required manual intervention on self-hosted instances, and
   client/server version coupling means an auto-updated desktop client can
   refuse to talk to a not-yet-upgraded server
   ([upgrade docs](https://docs.affine.pro/self-host-affine/install/upgrade),
   [v0.27.0 notes](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0)).
5. **Mobile gaps.** Not local-first — server down = no notes
   ([#13285](https://github.com/toeverything/AFFiNE/issues/13285)); a cluster of
   recent Android bugs: can't create workspace
   ([#14166](https://github.com/toeverything/AFFiNE/issues/14166)), pages
   missing unless previously opened on the phone
   ([#13859](https://github.com/toeverything/AFFiNE/issues/13859)), title/content
   entry failures ([#13838](https://github.com/toeverything/AFFiNE/issues/13838)),
   Chinese IME breakage with cloud sync
   ([#14033](https://github.com/toeverything/AFFiNE/issues/14033)).
6. **Self-host rough edges.** Desktop link previews/image proxy broken against
   self-hosted servers
   ([#14865](https://github.com/toeverything/AFFiNE/issues/14865)); telemetry
   reported as always-on for anonymous viewers
   ([#12821](https://github.com/toeverything/AFFiNE/issues/12821)); historical
   trust bruise from self-hosted instances initially shipping cloud-tier limits
   ([#6641](https://github.com/toeverything/AFFiNE/issues/6641)) — since
   resolved with Pro quota, but it shows pricing gates reach into self-host.
7. **No at-rest encryption for local storage** — open request since 2023
   ([#5491](https://github.com/toeverything/AFFiNE/issues/5491)).

## 10. Recommendation for this homelab

- **Trial it, don't migrate to it yet.** Deploy the official compose stack in a
  dedicated LXC/VM (4 vCPU / 4 GB / 30 GB to start, per the
  [requirements](https://docs.affine.pro/self-host-affine/install/requirements)),
  pin the image to `0.27.4` rather than `:stable`, put it behind NPM with
  websockets enabled, and run the Notion importer against a copy of the real
  workspace to see what survives.
- Backups: nightly `pg_dump` + restic of `./data/storage` and `./config`,
  matching the existing Technitium backup pattern. Do not rely on in-app export
  ([#8399](https://github.com/toeverything/AFFiNE/issues/8399)).
- Enable BYOK AI only if wanted, with `allowPrivateEndpoint` left off
  ([AI docs](https://docs.affine.pro/self-host-affine/administer/ai)).
- Decision hinges: if the daily-driver need is docs + whiteboard + journals
  with the data at home, AFFiNE is the strongest self-hostable option today.
  If it's Notion databases (relations/rollups) or heavy mobile capture, keep
  Notion or look at Anytype/SiYuan instead — AFFiNE's mobile and database
  stories are its two honest weaknesses, and both are structural enough that a
  patch release won't fix them.

## Sources

Primary:

- Repo/README: <https://github.com/toeverything/AFFiNE>
- Releases: <https://github.com/toeverything/AFFiNE/releases> (esp.
  [v0.27.0](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.0),
  [v0.27.4](https://github.com/toeverything/AFFiNE/releases/tag/v0.27.4))
- Licences: [LICENSE](https://github.com/toeverything/AFFiNE/blob/canary/LICENSE),
  [LICENSE-MIT](https://github.com/toeverything/AFFiNE/blob/canary/LICENSE-MIT),
  [EE licence](https://github.com/toeverything/AFFiNE/blob/canary/packages/backend/server/LICENSE)
- Self-host docs: [overview](https://docs.affine.pro/self-host-affine),
  [requirements](https://docs.affine.pro/self-host-affine/install/requirements),
  [compose reference](https://docs.affine.pro/self-host-affine/references/docker-compose-yml),
  [upgrade](https://docs.affine.pro/self-host-affine/install/upgrade),
  [after installation](https://docs.affine.pro/self-host-affine/install/after-installation),
  [OAuth](https://docs.affine.pro/self-host-affine/administer/oauth-2-0),
  [domain/HTTPS](https://docs.affine.pro/self-host-affine/administer/domain-and-https),
  [AI/BYOK](https://docs.affine.pro/self-host-affine/administer/ai),
  [team licence](https://docs.affine.pro/self-host-affine/features/team-license)
- Product pages: [pricing](https://affine.pro/pricing),
  [download](https://affine.pro/download), [AI](https://affine.pro/ai),
  [templates](https://affine.pro/templates)
- GitHub API stats (stars/forks/contributors/issues), captured 2026-08-24.

Community (labelled where used): GitHub issues/discussions linked inline
throughout §§1, 4, 5, 9; [fabric.so AFFiNE-vs-Notion comparison](https://fabric.so/comparison/affine-vs-notion);
[AFFiNE community forum](https://community.affine.pro);
[Tracxn company profile](https://tracxn.com/d/companies/affine/__Mo6BFrzUISfgrA8pldUKbTH0mEXrtjxwRlYfPIADZqs);
[spotSaaS pricing breakdown](https://www.spotsaas.com/product/affine/pricing).
