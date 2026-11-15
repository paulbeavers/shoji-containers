# CLAUDE.md — Shoji Containers

Companion app of `../shoji` (the tiling window manager): Docker containers and images. Created
2026-11-14 the same way as `../shoji-machines` (user: "clone the container functionality in the
same way we have shoji machines"). The Docker code came from MacLucent's Containers app
(`../mactile/Sources/MacLucent/Apps/ContainersApp.swift`, `DockerClient.swift` — see its CLAUDE.md
for the history: lenient decoding for Docker 29's `"Ports": null`, events stream, stats, etc.).

## Build, run

```bash
./scripts/build-app.sh               # → build/Shoji Containers.app
open "build/Shoji Containers.app"
```

- Ad-hoc signed with DR `identifier "dev.shoji.Containers"`; the build runs `lsregister -f` so
  Shoji's Mod+O finds it by that bundle id — don't change it.
- Themes: `scripts/sync-themes.sh` (../lucent, committed copy). Theme, `windowOpacity` and
  `hideTitleBars` come from Shoji's `~/.config/shoji/settings.json`; Shoji posts
  `dev.shoji.settingsChanged` on save and the window updates live.
- One instance at a time; closing the window quits (nothing runs in here without it).
- Commit and push only when asked; Co-Authored-By line at the end of commit messages.

## Distribution

Ships inside the Shoji installer: `../shoji/scripts/package.sh` builds this repo too and puts
Shoji Containers in the `.pkg`/`.dmg`, which `../shoji/scripts/deploy-web.sh` publishes on
https://shoji.pbcs.io (an end-user download page — see shoji's CLAUDE.md). A change here
reaches users only after a new package + deploy from the shoji repo. The installer's preinstall
script quits this app before replacing it.

## Files (Sources/ShojiContainers)

| File | Role |
|---|---|
| `main.swift`, `ContainersAppDelegate.swift` | App, window, menus, single instance, title bar per settings |
| `ContainersWindow.swift` | `ContainersApp` (tabs, rows, actions, pull/prune), row views |
| `DockerClient.swift` | Docker Engine API over the Unix socket (own HTTP/1.1 + chunked), API types |
| `Kitty.swift` | Opening kitty windows (`open -n -b net.kovidgoyal.kitty --args …`, optional `--hold`) |
| `Config.swift`, `Themes.swift`, `AppIcon.swift` | Settings from Shoji, Lucent themes, icon |
| `ContainersTest.swift` | Headless check against the real daemon |

## Differences from MacLucent's Containers

- Shell / logs / log history / run open **kitty windows** (logs and run with `--hold`, so the
  last output stays readable); open-port uses the default browser.

## Code review decisions (2026-11-14) — keep these

- **Removing an image with several tags** uses `DELETE /images/<id>?force=1` (without force
  Docker refuses: "image is referenced in multiple repositories"); the confirmation lists every tag.
- **Reloads:** `reload(images:)` fetches in parallel (`async let`) and bumps `reloadGeneration`;
  a result from an older reload is dropped (they raced and showed stale lists). The 3 s timer
  reloads containers only (`images: false`).
- Rows are rebuilt when the **shape** changes — ids, names, labels (Compose grouping) and the
  exit status, not just ids; otherwise a rename or a new exit code never showed.
- **Stream/connect races:** after `stream?.fd = fd` the client checks `isCancelled` (a cancel
  that landed before the fd existed left a stream open); an events stream's `onEnd` only acts if
  it's still the current stream; `connect()` has a `connecting` guard and a failed ping only
  disconnects when not already connected.
- `Kitty.open` returns false when kitty isn't installed and the caller shows an alert (it used to
  fail silently).
- **Translucency / hidden title bar:** rows are clear with a 1 px surface0 outline (the window
  already paints `windowOpacity`; a second fill stacked the alpha), selected/hover get a fill;
  content starts below `titlebarInset` (the hidden title-bar strip drags the window).
- `Config.load()` reloads the theme library (`ThemeLibrary.all(reload: true)`).

## Testing — the user's real Docker

- `SHOJI_CONTAINERS_TEST=<log> "build/Shoji Containers.app/Contents/MacOS/Shoji Containers"` (headless):
  lists containers/images through the app's own views. It only creates `shoji-test-*` containers
  and pulls `alpine:3.20`; it removes the containers, and removes the image only if it wasn't
  there before (`hadAlpine` — it once deleted the user's own copy). Needs Docker running; without
  it the log just says "no Docker socket".
- Never stop/remove the user's containers or images (they run real projects: b2c, crunch,
  focusly…). Don't trigger Remove/prune in a test (modal NSAlert on their screen).
