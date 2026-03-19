# Kiro IDE — Unofficial Flatpak

[![Build Status](https://github.com/orknist/kiro-desktop-flatpak/actions/workflows/update.yml/badge.svg)](https://github.com/orknist/kiro-desktop-flatpak/actions)

> **This is an unofficial, community-maintained Flatpak package.**  
> Kiro is a proprietary application developed by Amazon Web Services.  
> Official website: [kiro.dev](https://kiro.dev)

Kiro is an agentic AI IDE built on Code OSS (VS Code) that helps you go from
prototype to production with spec-driven development, agent hooks, and natural
language coding assistance.

**App ID:** `kiro.desktop.unofficial`  
This ID mirrors the official `.deb` package ID (`kiro.desktop`) while clearly
marking it as the unofficial Flatpak distribution.

---

## Why Flatpak?

- Works on any Linux distribution with Flatpak installed (Fedora, Ubuntu,
  Debian, Arch, openSUSE, etc.)
- Especially useful on **immutable distros** (Fedora Silverblue, openSUSE
  MicroOS, SteamOS, etc.) where installing `.tar.gz` or `.deb` packages
  directly is inconvenient or unsupported.
- No system-level dependency pollution — runs in its own sandbox.
- The built-in updater is disabled; version management is handled through this
  Flatpak package instead.

---

## Installation

### Via Flatpak repo (recommended)

```bash
# 1. Add this package's remote
flatpak remote-add --if-not-exists --no-gpg-verify --user kiro-unofficial \
  https://orknist.github.io/kiro-desktop-flatpak

# 2. Install
flatpak install --user kiro-unofficial kiro.desktop.unofficial
```

### Via .flatpak bundle

```bash
# Download the .flatpak file from the Releases page, then:
flatpak install --user kiro.desktop.unofficial.flatpak
```

### Running

```bash
flatpak run kiro.desktop.unofficial
```

### Updating

The repo is automatically updated every 6 hours via GitHub Actions.
To get the latest version:

```bash
flatpak update --user kiro.desktop.unofficial
```

---

## Building Locally

### Requirements

- `flatpak` and `flatpak-builder`
- `curl`, `jq`, `sha256sum`

```bash
git clone https://github.com/orknist/kiro-desktop-flatpak.git
cd kiro-desktop-flatpak

# Build only (creates a local repo)
./build.sh

# Build and install for the current user
./build.sh --install

# Build and produce a shareable .flatpak bundle
./build.sh --bundle
```

`build.sh` does the following on each run:

1. Queries Kiro's metadata API for the latest release URL
2. Downloads the archive (cached by version, skipped if already present)
3. Computes SHA256 and injects it into the manifest
4. Builds with `flatpak-builder`

---

## Sandbox Permissions

| Permission | Reason |
|---|---|
| `--filesystem=host` | Open projects from any directory |
| `--allow=devel` | Debugger / ptrace support |
| `--share=network` | Extensions, language servers, AI features |
| `--socket=wayland` + `x11` | Native Wayland + X11 fallback |
| `--talk-name=org.freedesktop.secrets` | Credential manager integration |
| `ELECTRON_NO_UPDATER=1` | Disables the built-in update mechanism |

---

## Updates

A GitHub Actions workflow checks Kiro's metadata API every 6 hours:

```
https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json
```

When a new version is detected, it automatically builds the Flatpak, deploys
the repo to GitHub Pages, and creates a GitHub Release with the `.flatpak`
bundle. You can also trigger a build manually from the Actions tab.

---

## Issues & Contributions

- **Flatpak packaging issues:** [Open an issue in this repo](https://github.com/orknist/kiro-desktop-flatpak/issues)
- **Issues with Kiro itself:** [kirodotdev/Kiro](https://github.com/kirodotdev/Kiro/issues)

---

## License

The build scripts and manifest files in this repository are licensed under
**MIT**. Kiro itself is proprietary software owned by Amazon Web Services and
is subject to its [terms of service](https://kiro.dev).
