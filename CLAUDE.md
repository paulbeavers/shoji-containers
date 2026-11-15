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

## Testing — the user's real Docker

- `SHOJI_CONTAINERS_TEST=<log> "build/Shoji Containers.app/Contents/MacOS/Shoji Containers"` (headless):
  lists containers/images through the app's own views. It only creates `shoji-test-*` containers
  and pulls `alpine:3.20`, and removes both — check the user doesn't have `alpine:3.20` first.
- Never stop/remove the user's containers or images (they run real projects: b2c, crunch,
  focusly…). Don't trigger Remove/prune in a test (modal NSAlert on their screen).
