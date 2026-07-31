# Palworld 1.0 dedicated-server Pal movement and network research

**Research date:** 2026-07-31
**Scope:** Palworld `1.0` (released 2026-07-10) through
`v1.0.2.101103`. No live-server changes were made.

## Bottom line

- **The symptom is credible, but there is no proven universal configuration
  fix.** Independent post-1.0 reports describe player rubber-banding and Pals
  lagging, teleporting, falling through terrain, disappearing from bases, and
  failing to path. Reports span official servers, rented servers, Docker, and
  local Steam dedicated servers. Other operators report clean play, so these
  anecdotes establish occurrence, not a single cause.
- **Separate two failure classes:** low or unstable server FPS can produce
  movement corrections and delayed hits; Pal AI/pathfinding/replication bugs
  can occur even when server tick appears healthy. A network-rate tweak cannot
  be assumed to fix the latter.
- **Do not paste the recycled 2024 “anti-rubberband” `Engine.ini` block into
  production.** Post-1.0 evidence for `120` tick is two uncontrolled anecdotes,
  one only saying it “might” have helped; another measured post already using
  `120` plus the large bandwidth values still recorded server FPS collapsing to
  11–37. The huge `104857600` rate values have no current Palworld validation.
- **The first worthwhile controlled test is the startup flags.** Pocketpair's
  current 1.0.2 guide says leaving
  `-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS` unset *may
  improve* 1.0+ performance, while Pocketpair's current Docker sample still
  includes them. That contradiction needs an A/B test, not faith.

## What changed officially

Pocketpair's 1.0 notes claim dedicated-server optimisation, multiplayer
synchronisation fixes, reduced cases of wild Pals/NPCs getting stuck or
zigzagging, and fixes for base Pals clipping through the ground or failing to
resume work. The same notes also fixed one dedicated-server case where charging
enemy Pals teleported into walls. These are broad claims, not evidence that all
such defects were eliminated. [Official 1.0 changelog, 10
July](https://steamcommunity.com/ogg/1623730/announcements/detail/1837955055355658)

The subsequent patches are narrower:

- `1.0.1` fixed save loss and a persistent burning status; it contains no
  general server, movement, pathfinding, or replication fix. [Official 1.0.1
  notes, 15
  July](https://steamcommunity.com/ogg/1623730/announcements/detail/1838407329253279)
- `1.0.2` fixed specific multiplayer/dedicated-server faults: Panthalus
  disconnects/crashes, Victor & Shadowbeak disappearing after a teleport, World
  Tree terrain display, and Sunreach processing load. It did **not** claim a
  general rubber-band or base-Pal fix. [Official 1.0.2 notes, 29
  July](https://steamcommunity.com/ogg/1623730/announcements/detail/1839676055881423)
- `1.0.2.101103` only fixed an infinite load after the World Tree boss.
  [Official build notes, 30
  July](https://steamcommunity.com/ogg/1623730/announcements/detail/1839676055885050)

## Current community evidence

| Date | Original report | What it supports | Limits |
| --- | --- | --- | --- |
| 2026-07-11 | A fresh 1.0 Steam dedicated-server thread reports Pals teleporting in combat, attacks crossing terrain, and base Pals still getting stuck/not pathing. Other participants report idle hangs and crashes. [Steam discussion](https://steamcommunity.com/app/1623730/discussions/0/568165608207820520/) | The problem persisted for at least some 1.0 servers immediately after launch. | Mixed symptoms and hosts; no measurements or controlled comparison. |
| 2026-07-12 | A Docker/Wings server on a Ryzen 5800X, four cores and 16 GB reported Pals falling through the floor, disappearing/reappearing away from base, and being flung across a zone. The reporter said server tick looked healthy and network tweaks did not help. [Reddit report](https://www.reddit.com/r/Palworld/comments/1uu5izz/is_anyone_elses_dedicated_server_experience_still/) | Strongest direct match for the reported base-Pal behaviour and evidence that a healthy-looking tick does not rule out game/replication bugs. | Self-reported; no logs or before/after capture. One rented-server user in the same thread reported no desync. |
| 2026-07-11–16 | G-Portal players reported delayed hits and rubber-banding after 1.0. One user said changing the provider's server tick setting to `60` made it instantly smoother; another said G-Portal had reset it to `10` or `30` after updates. [Reddit report](https://www.reddit.com/r/Palworld/comments/1utd5du/how_much_lag_is_normal_for_a_server/) | `60` is a reasonable test value when observed server FPS/tick is abnormally low. | Provider control may not map exactly to `NetServerMaxTickRate`; one uncontrolled success. |
| 2026-07-14 | A local Windows server on an i9-14900KF showed player moonwalking and small Pal rewinds. The operator said adding both tick-rate keys at `120` “might” have fixed it. [Reddit report](https://www.reddit.com/r/Palworld/comments/1uw1crx/palword_steam_dedicated_server/) | Current, but very weak, support for testing a tick override. | No measurement, short follow-up, two variables changed, and host also ran the client. |
| 2026-07-14 | A 1.0 Docker server using host networking and the full `120`/`104857600` Engine block measured server FPS bursts down to 11–37, frame time up to 84 ms, low network use, and one apparent saturated core while total CPU remained 50–60%. [Reddit report](https://www.reddit.com/r/PalworldMods/comments/1uw4wdk/dedicated_server_pegged_to_a_single_thread_with/) | Shows that host networking, the folklore Engine block, spare aggregate CPU, and low bandwidth do not prevent severe server-frame stalls. It supports checking per-thread CPU rather than aggregate CPU. | One shared-vCPU VPS; the reporter inferred rather than profiled the game thread. |
| 2026-07-15 | Official-server player reports regular rubber-banding and Pals lagging in combat and at base; another participant reports lag on a dedicated server hosted on the same PC. [Reddit report](https://www.reddit.com/r/Palworld/comments/1uxnuuo/is_the_desync_common_on_all_full_official_servers/) | Rules out “Docker bridge alone” as a general explanation. | Official-server load and local co-host contention are confounders. |
| 2026-07-13 | A pathing-specific thread contains both “no issue in 1.0” and successful multi-floor-base reports. [Reddit report](https://www.reddit.com/r/Palworld/comments/1uuwkxg/how_is_pal_pathing_in_the_new_update_improvements/) | Pathing is not universally broken; base geometry and Pal choice remain plausible modifiers. | Small sample and no dedicated-versus-single-player control. |

Overall confidence that the observed phenomenon exists on 1.0 dedicated
servers is **high**. Confidence that it is caused by network bandwidth, Docker,
or one setting is **low**.

## Configuration findings

### Tick rate and Unreal bandwidth settings

Epic documents `NetServerMaxTickRate` as an upper limit on dedicated-server
tick rate and warns that tick rate affects behaviour including the bandwidth
limit for a network update. `MaxNetTickRate`, `MaxClientRate`, and
`MaxInternetClientRate` are separate configured limits. [Epic
`UNetDriver`](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UNetDriver)
[Epic network testing
guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/testing-and-debugging-networked-games-in-unreal-engine)

Current Pocketpair documentation does not prescribe a Palworld tick rate or any
of the common `Engine.ini` bandwidth values. Current Epic UE5 API documentation
exposes `NetServerMaxTickRate`, but a search of the corresponding current
`UNetDriver` and `UIpNetDriver` APIs found no `LanServerMaxTickRate`. Treat the
LAN key as unverified legacy configuration unless an A/B test proves it changes
the reported server rate.

**Judgement:** test stock/default versus `60` first. Test `120` only if the
server can already sustain 60 with ample per-thread headroom. Do not combine the
tick test with the `104857600` bandwidth block.

### `ServerReplicatePawnCullDistance`

Pocketpair defines this as Pal synchronisation distance from a player, with a
supported range of `5000`–`15000` cm (50–150 m). It is a relevancy/load control,
not a pathfinding control. [Pocketpair 1.0.2 configuration
reference](https://docs.palworldgame.com/settings-and-operation/configuration/)

There is no controlled post-1.0 evidence for a best value. `15000` is the 1.0
default present in current default-setting examples; `10000` is a defensible
load experiment, not a fix. Lowering it can itself make distant Pals disappear
and pop back in, so it may make a teleport-like visual symptom worse.

### Multithreading flags and `NumberOfWorkerThreadsServer`

Pocketpair's current guide says omitting the three performance flags may improve
performance in 1.0+, yet its example and current official Docker Compose still
include them. `NumberOfWorkerThreadsServer=X` is documented as requiring those
performance arguments. [Pocketpair argument
guide](https://docs.palworldgame.com/settings-and-operation/arguments/)
[Official Docker
Compose](https://github.com/pocketpairjp/palworld-dedicated-server-docker/blob/main/compose/compose.yaml)

Older Pocketpair documentation recommended no more than `CPU thread-count - 1`;
that guidance is absent from the current 1.0.2 performance section and should be
labelled legacy rather than silently carried forward. The repository's declared
server has six vCPUs but no explicit worker-thread override. Its Compose file
does include the three flags. [Local declared
configuration](../../stacks/pve/palworld-lxc/docker-compose.yml)

**Judgement:** the clean 1.0 baseline is no triplet and no explicit worker
count. Compare that with the current triplet. Only then, if the triplet wins,
test `NumberOfWorkerThreadsServer=5` as a legacy-derived third branch.

### Docker networking

Pocketpair's official and this repository's Compose samples publish
`8211/udp` through Docker's normal bridge; Pocketpair does not recommend host
networking for performance. A current report still had serious frame stalls
with host networking. Docker Desktop is officially discouraged for storage-I/O
and save-integrity reasons, but that warning does not apply to native Linux
Docker in an Alpine LXC. [Pocketpair
requirements](https://docs.palworldgame.com/getting-started/requirements/)

**Judgement:** bridge networking is not the leading suspect. Only A/B it after
showing packet drops, queue pressure, or good server FPS concurrent with bad
client RTT.

### CPU affinity and single-thread performance

Pocketpair specifies four or more cores but does not document affinity or a
single-thread requirement. The measured July report makes a main-thread
bottleneck plausible, not proven. There is no current controlled Palworld 1.0
evidence that pinning helps.

**Judgement:** inspect per-thread saturation and host contention first. Affinity
is a late A/B test; pinning too tightly can reduce performance.

## Read-only checks before changing anything

1. Record exact client/server build, running command line, config hashes, uptime,
   mod status, player count, base count, and active base-Pal count.
2. Reproduce one fixed scenario for 20–30 minutes: same two clients, base,
   roster, route, and camera. Log issue timestamps and simultaneously record
   server FPS/frame time from the in-game server information.
3. Sample per-thread CPU, process RSS, Docker CPU/memory, host load, and CPU
   migrations. Aggregate CPU alone is not useful.
4. Record `ip -s link`, UDP/socket counters, and Docker/host-interface drops
   before and after the run. A LAN `ping` proves only basic RTT, not Palworld UDP
   health.
5. If the REST API is **already enabled**, Pocketpair's read-only `/metrics`
   endpoint returns `serverfps`, `serverframetime`, players, uptime, and base
   count. Do not expose its management port merely to collect this.
   [Pocketpair metrics API](https://docs.palworldgame.com/api/rest-api/metrics/)
6. On a disposable test server, `-enable-gamedata-api` can provide server-side
   BaseCampPal positions, `Action`, and `AI_Action`. Comparing these snapshots
   with client video can distinguish a server-authoritative teleport from
   client interpolation/correction. [Pocketpair game-data
   API](https://docs.palworldgame.com/api/rest-api/game-data/)

## Controlled A/B order

Use a backed-up save copy or disposable test server, change one variable per
restart, use the same workload, and compare median/p95 frame time, minimum
server FPS, per-thread CPU, interface drops, and counted Pal/player corrections.

1. **Startup flags:** current triplet versus no triplet; leave worker count
   unset.
2. **Tick cap:** stock/default versus `NetServerMaxTickRate=60`. Only test `120`
   if 60 is sustained. Add `LanServerMaxTickRate=60` as a separate branch only
   if the Net key alone demonstrably does not change the rate.
3. **Worker count:** only if the triplet wins; unset versus `5` on the declared
   six-vCPU allocation.
4. **Pawn cull:** `15000` versus `10000`, specifically under multiple players
   spread around Pal-heavy bases. Reject `10000` if pop-in/corrections increase.
5. **Docker network:** bridge versus host mode, only after a clean tick/CPU run
   still shows network symptoms.
6. **CPU placement:** unrestricted versus dedicated/pinned physical cores on
   PVE, only if measurements show migrations, contention, or one saturated
   thread. Keep the same vCPU count.
7. **Bandwidth/rate block:** last, and only if measured connection saturation
   exists. Do not start with `104857600`; choose rates from actual per-client
   traffic and change one limit at a time.

The most likely useful result is not “the magic number”; it is classification:
**server-frame starvation**, **actual network loss/queueing**, or a
**server-authoritative Pal AI/replication defect**. That determines whether
hardware/config work can help or whether the correct action is to preserve a
minimal reproduction for Pocketpair.
