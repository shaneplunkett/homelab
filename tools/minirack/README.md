# minirack ✿

A little visual planner for the 10" minirack. Drag gear into the rack, plug
cables between ports, and leave notes on anything.

```sh
bun tools/minirack/server.ts
# → http://127.0.0.1:4545
```

There are no dependencies to install, just Bun. Set `PORT` or `HOST` to change
where it listens (`HOST=0.0.0.0` to reach it from another machine).

## Where the layout lives

Everything saves automatically to [`rack.json`](rack.json) as you go, so
committing that file is how a layout persists. If the file changes on disk
while a tab is open (a `git pull`, say), the app notices and asks which
version to keep, so it never silently overwrites.

## Using it

- Open the 🧺 gear drawer and drag things into the rack, or click one to drop
  it in the first free spot. Half-width things snap to the left or right side.
- The parking bay holds gear that doesn't have a home yet.
- Click a port, then another port, to plug in a cable. Clicking a plugged
  port selects its cable.
- Flip between front and rear with the toggle or `V`. The rear is mirrored,
  as it is when you're standing behind the rack. Each port lives on the
  front, the rear, or both (patch panel keystones pass straight through), and
  a cable whose other end is on the far side shows up as a ↻ stub.
- Click (or right-click) anything to open a little card beside it, where you
  can rename it, recolour it, label its ports, or write notes. Layout settings
  live under ⚙ in the top bar, or right-click the empty canvas.
  "Refresh from template" gives an item the latest ports and size from the
  palette while keeping its name, colour, notes and spot.
- Use layout tabs to keep "how it is now" next to "how I want it". Duplicate
  a layout to start a new plan from the current one.
- `Ctrl+Z` / `Ctrl+Shift+Z` undo and redo, `Delete` removes the selected
  thing, and `Esc` cancels.
