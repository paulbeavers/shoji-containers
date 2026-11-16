# Shoji Containers

Docker containers and images for macOS, a companion app of [Shoji](../shoji) (a Hyprland-style
tiling window manager). Shoji opens it with **Mod+O**.

```bash
./scripts/build-app.sh               # → build/Shoji Containers.app (registered with macOS for Shoji)
open "build/Shoji Containers.app"
```

- **Containers:** running ones (or all, with Show stopped), grouped by Compose project, with
  status, ports and live CPU/memory. Start/stop/resume, restart, remove; **shell**
  (`docker exec`), **live logs** and **log history** open in kitty windows; **open** a published
  port in your default browser.
- **Images:** size, age, which containers use them; **pull** with progress, **run** in a kitty
  window, remove, and remove unused (untagged) images.
- Live: follows Docker's event stream, so changes from the `docker` CLI show up at once.
- Works with Docker Desktop, OrbStack, Colima, Podman and Rancher Desktop (finds the socket like
  the `docker` CLI does).
- Follows Shoji's theme and Windows settings (opacity, title bars).

Requires macOS 13+, kitty, a Docker engine, and a Swift toolchain to build.

## License

MIT — see [LICENSE](LICENSE).
