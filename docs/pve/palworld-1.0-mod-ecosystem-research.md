# Palworld 1.0 mod ecosystem and dedicated-server compatibility

**Research date:** 2026-08-10  
**Server scope:** Pocketpair's official native-Linux container,
`ghcr.io/pocketpairjp/palserver:v1.0.2.101103`, as declared in
[`stacks/pve/palworld-lxc/docker-compose.yml`](../../stacks/pve/palworld-lxc/docker-compose.yml).
No live-server changes were made.

## Bottom line

- **There is no Pocketpair-supported runtime mod path on the current server.**
  Pocketpair's current guide says server-side mods work only on the
  **Windows** dedicated server. The official image in this repository runs the
  native Linux server, so its official mod-loader path is unavailable. A mod
  author does document a raw Linux `.pak` exception for Guild Storage Expander,
  but that is outside Pocketpair's supported loader. [Pocketpair server-mod
  guide](https://docs.palworldgame.com/settings-and-operation/mod)
- **Client-only display, camera and cosmetic mods can leave the server
  untouched.** Each player installs them locally; the server only needs to
  permit modded clients through `bAllowClientMod`. Check that setting before
  assuming a client will be admitted. [Pocketpair configuration
  reference](https://docs.palworldgame.com/settings-and-operation/configuration)
- **The world was freshly reset and currently has no players or guild.** A
  creation-time chest mod is therefore timely, but the supported Windows-only
  boundary still applies. Once the first guild and chest exist, an offline
  save edit is the cleanest no-runtime fit: it needs no UE4SS, PalSchema or
  Windows server process and retains the official Linux image. No edit was
  performed during this research.
- **Treat “Palworld 1.0 compatible” as necessary, not sufficient.** Palworld's
  1.0 launch invalidated old mod data, and Pocketpair told players to remove
  old UE4SS, LogicMods, Paks and Workshop remnants. A mod updated after 10 July
  is fresher evidence, but only an author claim or an isolated test proves a
  particular game build. [Pocketpair's 1.0 mod
  warning](https://steamcommunity.com/ogg/1623730/announcements/detail/1824644522844567)

## The platform boundary

Palworld 1.0 introduced an official Steam Workshop/mod-loader workflow. The
loader uses `Mods/PalModSettings.ini`, an `Info.json` package identity and
install rules. It can deploy five payload types:

| Package type | Official loader destination | What it means |
| --- | --- | --- |
| UE4SS | `Mods/NativeMods/UE4SS` | Native code-injection framework; broadest capability and blast radius. |
| Lua | `Mods/NativeMods/UE4SS/Mods/{PackageName}` | Runtime script loaded by UE4SS. |
| PalSchema | `Mods/NativeMods/UE4SS/Mods/PalSchema/mods` | JSON/JSONC runtime changes to data tables and Blueprints, layered through PalSchema and UE4SS. |
| LogicMods | `Pal/Content/Paks/LogicMods` | Cooked Blueprint/content package loaded as a logic mod. |
| Paks | `Pal/Content/Paks/~WorkshopMods` | Cooked asset/content override. Traditional Nexus packages may instead tell users to use `~mods`; follow the author's current package instructions, not an old generic guide. |

The official package spec requires a separate install rule with
`"IsServer": true` for a dedicated-server payload. A package can target the
client, the server, or both by carrying different rules. [Pocketpair Mod
Uploader technical reference](https://github.com/pocketpairjp/PalworldModUploader/blob/main/PalworldModUploader/docs/en/04-Tech.md)

That packaging support does **not** remove the operating-system restriction:
Pocketpair's current server guide still says server mods are Windows-only.
Shane's server is the official native-Linux image, whose own current Compose
sample is also pinned to `v1.0.2.101103`. [Pocketpair official container
sample](https://github.com/pocketpairjp/palworld-dedicated-server-docker/blob/main/compose/compose.yaml)

One mod author documents an unsupported-by-Pocketpair exception: [Guild Storage
Expander](https://steamcommunity.com/sharedfiles/filedetails/?id=3764798774)
ships a server-only raw `.pak` and gives native-Linux instructions to place it
under `Pal/Content/Paks/~mods`. It raises newly created guild chests from 54 to
444 slots without a client install. Its 7 August update added Linux/server
instructions, but the actual release was built for `1.0.0.100427`, not
explicitly revalidated against `1.0.2.101103`. The official container persists
only `Saved`, so a production implementation would also need a declared bind
mount rather than copying the file into an ephemeral container layer. This is
a viable experiment on a disposable world, not official Linux mod support.

An unofficial alternative is to replace the Linux server with the Windows
server under Wine. It is not a drop-in mod install. A current upstream report
shows PalSchema 0.6.1 hanging during startup under Wine even with the 19 July
Palworld UE4SS build, while another open 1.0 issue reports client connections
failing with UE4SS installed. These are reports, not proof that every setup
fails, but they make a Wine migration a separate experimental project rather
than a reasonable storage tweak. [Wine/PalSchema hang
report](https://github.com/UE4SS-RE/RE-UE4SS/issues/1364) [Palworld 1.0 UE4SS
connection report](https://github.com/UE4SS-RE/RE-UE4SS/issues/1339)

## Current frameworks

| Framework | Freshness at research date | Multiplayer/server position | Main risk |
| --- | --- | --- | --- |
| [Official Workshop/mod loader](https://docs.palworldgame.com/settings-and-operation/mod) | Current Pocketpair 1.0.2 docs | Client loader is current; server loader is Windows-only. | A Workshop label does not prove the payload is client-only or safe for a save. Inspect `Info.json` and the author's compatibility notes. |
| [Okaetsu's Palworld UE4SS fork](https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld) | Palworld build updated 2026-07-19, commit `c838a8a` | Required by current PalSchema and many native/Lua mods. Not a native-Linux server path. | Injects native code. Duplicate manual and Workshop copies crash by the maintainer's own warning; game updates can invalidate signatures/layouts. |
| [PalSchema 0.6.1](https://github.com/Okaetsu/PalSchema/releases/tag/0.6.1) | Released 2026-07-19 for current UE4SS fork | Runtime asset edits with lower mod-to-mod collision than whole-asset replacements; dedicated-server support exists on Windows. | Still inherits UE4SS version lock and code-injection risk. Schema changes may affect newly created objects only. |
| Raw `.pak` / LogicMods | Per-mod, not one framework version | Can be visual client-only, authoritative gameplay, server-only, or both. The file extension does not answer deployment scope. | Whole-asset overrides conflict when two mods replace the same asset; stale Paks were specifically called out by Pocketpair before 1.0. |

PalSchema's author describes it as JSON-based modification of data tables and
Blueprints without replacing entire assets, reducing conflicts between schema
mods. It is not a sandbox: it is a C++ mod loaded by the Palworld-specific
UE4SS fork. [PalSchema repository](https://github.com/Okaetsu/PalSchema)

## Representative maintained 1.0 mods

This is a compatibility map, not a popularity ranking. Freshness records the
author's last update visible on 10 August 2026. “Server untouched” means no
files or runtime are installed on the server; it does not mean the server will
admit the client unless `bAllowClientMod` permits it.

| Category and example | Runtime placement | Dedicated multiplayer | Freshness and fit for `1.0.2.101103` | Material risks |
| --- | --- | --- | --- | --- |
| Camera/immersion — [Immersive Palworld (First Person)](https://www.nexusmods.com/palworld/mods/4655) | **Client-only**; official Workshop plus Palworld UE4SS. | Author explicitly says multiplayer-compatible and no server installation; each interested player installs it. **Server untouched.** | v1.0.1, updated 2026-08-07; author targets Palworld 1.0, not the exact Pocketpair build string. | Camera/FOV/HUD/foliage mods can conflict; author lists rare camera/crash reports. |
| Map/UI — [Map Collectables Overhauled](https://www.nexusmods.com/palworld/mods/3724) | Native C++ UE4SS mod on the client. | Author marks multiplayer supported and gives only client install paths; some markers may appear only when nearby. **Server untouched** is a reasonable inference, not an explicit server statement. | v2.0.7, updated 2026-08-09; rebuilt for Palworld 1.0. | Native DLL. Remove the obsolete LogicMods `.pak` or both copies load; Vortex needs Palworld integration 0.3.0. |
| Admin/creative tools — [Creative Menu](https://www.nexusmods.com/palworld/mods/703) | `.pak`; **both server/host and using client** for multiplayer. | Author requires the dedicated server to have the mod and the user to be an admin or permitted; client and server/host both need it. **Blocked on the current Linux server.** | v1.2.4, updated 2026-07-12 with 1.0 content/fixes. | Can create items, Pals and illegal stats; high gameplay/integrity impact even when technically compatible. |
| Base automation — [Palworld Base Automation](https://www.nexusmods.com/palworld/mods/3691) | UE4SS Lua/native package plus a UI LogicMod; server UE4SS folder supplies authoritative automation, clients install the package for F10 UI. | Server required for automation; clients alone cannot automate another server. Headless config is through the mod's INI files. **Blocked on current Linux.** | Nexus updated 2026-08-04; internal stable noted as v4.7.1. | Author documents limited dedicated/headless support, a same-process world-reload crash, conflicts with competing recipe/queue mods, and copied-save testing. Guild Chest is not directly supported. |
| Broad rebalance — [Complete Game Rebalance](https://www.nexusmods.com/palworld/mods/2166) | PalSchema + Palworld UE4SS on each participating game/host. | Author claims co-op support with installation on all clients, but does not document native-Linux dedicated support. **Do not assume dedicated compatibility.** | v1.0.2, updated 2026-08-06; author explicitly claims Palworld v1.0.2. | Wide surface: progression, recipes, drops, work, storage and more. Author says mods touching the same data are incompatible. Guild Chest 300 applies only to new guilds/characters. |
| Configurable storage — [Custom Container Slots](https://www.nexusmods.com/palworld/mods/2428) | PalSchema + UE4SS where the authoritative world/object is created. | Existing containers are unchanged; ordinary containers need rebuilding and a Guild Chest needs a newly created guild or save edit. **Its runtime server path is blocked on current Linux.** | v2.0, updated 2026-08-04; current PalSchema format. | Invalid JSONC breaks the mod; decreasing pouch size can delete inaccessible items; values remain on created containers after uninstall. |

Older client mods can still work, but freshness matters. For example, Pal Info
labels itself client-only and multiplayer-capable, yet its Nexus file was last
updated in February 2025 and still points at generic UE4SS 3.0.1 rather than the
current Palworld fork. It is evidence of a category, not strong 1.0.2
compatibility evidence. [Pal Info author page](https://www.nexusmods.com/palworld/mods/178)

## Guild Chest and storage expansion

### The important save behaviour

Guild Chest capacity is persisted in the world save. Schema mods that change
`GuildChestSlotNum` affect creation; they do not retroactively resize an
existing guild's stored container. That is why current mod pages repeatedly
say “new guild”, and why removing a creation-time mod does not return an
already-created chest to 54 slots.

The broad choices are:

| Option | Scope | Existing guild | Current Linux server | Freshness | Assessment |
| --- | --- | --- | --- | --- | --- |
| [Guild Storage Expander](https://steamcommunity.com/sharedfiles/filedetails/?id=3764798774) | Server-only raw `_P.pak`; no client dependency; 444 slots. | No: applies when a guild is created. Removing it does not shrink a chest already created at 444. | **Author-documented Linux path, outside Pocketpair support.** Needs a persistent bind mount with the official container. | Linux/server instructions updated 2026-08-07; binary originally targeted `1.0.0.100427`, not explicitly `1.0.2.101103`. | Timely for the current empty world, but test before the first production guild and retain only if future guilds also need 444 slots. |
| [358 / 2466 GuildChest Slots](https://www.nexusmods.com/palworld/mods/3434) | Author says **server-only**, either PalSchema or `_P.pak`; clients need nothing. | No: only guilds created after install; fresh worlds affect all new guilds. | **Unavailable through Pocketpair's supported loader.** The standalone `_P.pak`, not PalSchema, is the only plausible native-Linux experiment. | Updated 2026-07-16. | Less directly documented for Linux than Guild Storage Expander. Avoid 2466: the [independent resizer test](https://github.com/Leo927/palworld-guild-chest-resizer/releases/tag/v1.0.0) measured severe UI delay at roughly this scale. |
| [Custom Container Slots](https://www.nexusmods.com/palworld/mods/2428) | PalSchema runtime; configurable chest, food, medicine, recycler, pouch and Guild Chest slots. | No retroactive resize. Guild Chest requires a new guild or save editing. | **Blocked at runtime.** | Updated 2026-08-04. | Better when many container types need deliberate sizes, but far more change than the requested Guild Chest fix. |
| [Easy Guild Storage Slots](https://www.nexusmods.com/palworld/mods/4730) | One-time `.pak` “unlocker” with 108/270/540/5400 variants; author says open/build, save, then remove it. | Author claims opening an existing chest applies increases. | The page does **not** explicitly document dedicated-server authority or Linux-server compatibility. | Uploaded/updated 2026-08-03. | Interesting, but do not let a client mutate the production world's authoritative storage based only on this claim. Validate on an isolated copy first. |
| [Complete Game Rebalance](https://www.nexusmods.com/palworld/mods/2166) | PalSchema overhaul; all participating co-op clients. | 300 slots only for new multiplayer guilds/new single-player characters. | **Blocked at runtime** and excessively broad. | Updated 2026-08-06. | Do not adopt an overhaul to solve one storage limit. |
| [Palworld Guild Chest Resizer](https://github.com/Leo927/palworld-guild-chest-resizer) | Offline open-source save tool; no runtime mod, UE4SS or PalSchema. | **Yes.** Changes the saved `SlotNum` and retains contents. | **Yes, on an offline copy.** Linux support needs a locally built `libooz.so`; Windows setup is easier. | [v1.0.0](https://github.com/Leo927/palworld-guild-chest-resizer/releases/tag/v1.0.0), released 2026-07-25 for 0.6+ Oodle saves. | Best architectural fit once a guild chest exists. Author measured no noticeable delay at 150–360 slots but about a 20-second freeze around 2500. It writes zlib temporarily because there is no open Oodle compressor; the game rewrites Oodle on its next save. |
| [Guild Chest Fix](https://github.com/DSSidhu2206/GuildChestFix) | Offline Windows executable/source companion to a 444-slot Workshop mod. | **Yes**, raises existing guilds to 54–444 without shrinking. | **Yes, by editing an offline copy**; run the executable under Wine/Proton or on a Windows workstation. | v1.5.1 released 2026-08-10. | More packaged and freshly released. It makes a backup, verifies the edit and publishes GitHub build provenance. The unsigned PyInstaller app may trigger antivirus; it may fetch a checksummed Oodle DLL if none is available. Licence is personal/non-commercial, not MIT. |

### Recommended path for Shane's server

1. **Keep the official native-Linux server.** Do not migrate to Wine or add
   UE4SS merely for chest slots.
2. **Choose a restrained size in the low hundreds.** The resizer author warns
   that every slot is serialised into `Level.sav` and laid out when the UI
   opens; 270, 358 or 444 is a more defensible test than 2466 or 5400.
3. **Decide before the first guild is created:** either stay vanilla now and
   use an offline resize after the chest exists, or isolated-test Guild Storage
   Expander's raw Linux `.pak` if all future guilds must start at 444. The raw
   `.pak` path needs a repository-declared persistent mount; do not copy it into
   the live container by hand.
4. **Use an offline save tool only on a disposable copy first.** The
   `palworld-guild-chest-resizer` has the clearest technical description and
   item-preservation/shrink guards; `GuildChestFix` has the fresher packaged
   release and build provenance. Neither should touch the running server.
5. **Require a complete world backup, stopped server, round-trip load test and
   item-count check** before any production restore. A `Level.sav`-only backup
   is not the same recovery path as the repository's whole-world restic
   backup.

This is a recommendation, not an applied change. The existing
[`palworld.md`](palworld.md) backup and controlled-stop procedure remains the
authority for any later production work.

## Risk and compatibility checklist

- Record the exact client and server build. “1.0” and even “1.0.2” do not prove
  compatibility with `1.0.2.101103`.
- Read the mod author's current Files/Description page and inspect `Info.json`
  where available. Do not infer client/server scope from `.pak` alone.
- Never keep both manual and Workshop UE4SS copies. The Palworld fork's release
  notes say loading two copies will crash.
- Remove stale `~mods`, `LogicMods`, UE4SS and Workshop remnants before a clean
  test, following Pocketpair's 1.0 warning.
- Add one mod at a time, on a copied save, with a reproducible launch/load/join,
  chest open, save, restart and reconnect test.
- For client-only mods, confirm `bAllowClientMod`, then test one client while
  leaving the server filesystem and process untouched.
- Treat native C++/UE4SS mods as arbitrary code from the mod author. Prefer
  source-backed releases, reproducible builds and narrow capability.
- For save editors, stop all writers and auto-restart managers, preserve the
  whole world, verify the tool's output by reopening it, and prove rollback
  before production use.

## Confidence and gaps

- **High confidence:** Pocketpair's current Windows-only server-mod boundary;
  the current server's native-Linux official image; official loader paths and
  package targeting; author-stated deployment requirements above.
- **Medium confidence:** post-1.0 mods updated in August will behave on the exact
  `101103` build. The pages usually claim 1.0 or 1.0.2 rather than that full
  server build, and this research did not execute them.
- **Low confidence:** Easy Guild Storage Slots on an existing dedicated-server
  guild. The author demonstrates a one-time client/host flow but does not
  document server authority, client/server deployment, or this Linux build.
- Nexus/Workshop pages, repositories and releases were inspected as mod-author
  sources. No claims of ecosystem-wide popularity are made.
