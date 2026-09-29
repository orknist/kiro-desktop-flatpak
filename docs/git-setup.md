# Kiro (Flatpak) + Git Setup Guide

> Applies to: `kiro.desktop.unofficial` Flatpak on systems with git
> Tested on: Fedora KDE 45

---

## Prerequisites

- Git installed

```bash
sudo dnf install git
```

---

## 1. Create the `git` wrapper

Kiro runs in a Flatpak sandbox and cannot see the host's `/usr/bin/git`.
We use `flatpak-spawn --host` to bridge the sandbox to the host binary.

```bash
mkdir -p ~/.var/app/kiro.desktop.unofficial/data/bin

cat > ~/.var/app/kiro.desktop.unofficial/data/bin/git << 'EOF'
#!/bin/bash
exec /usr/bin/flatpak-spawn --host git "$@"
EOF

chmod +x ~/.var/app/kiro.desktop.unofficial/data/bin/git
```

Verify it works:

```bash
~/.var/app/kiro.desktop.unofficial/data/bin/git status
```

---

## 2. Apply Flatpak overrides

```bash
flatpak override --user \
  --filesystem=/tmp \
  --env="PATH=/home/$USER/.var/app/kiro.desktop.unofficial/data/bin:/app/bin:/usr/bin" \
  --talk-name=org.freedesktop.Flatpak \
  kiro.desktop.unofficial
```

Verify overrides:

```bash
flatpak override --user --show kiro.desktop.unofficial
```

---

## 3. Configure Kiro settings

In Kiro's `settings.json`:

```json
{
  "git.path": "/home/YOUR_USERNAME/.var/app/kiro.desktop.unofficial/data/bin/git"
}
```

Replace `YOUR_USERNAME` with your actual username.

---

## Notes

- Flatpak overrides persist across Flatpak updates and are stored at:
  `~/.local/share/flatpak/overrides/kiro.desktop.unofficial`
- The wrapper script in `data/bin/` also persists across updates.
- If you run as a different UID than `1000`, adjust the socket path accordingly:
  ```bash
  echo $UID
  ```
- On **mutable** distros (standard Ubuntu, Fedora Workstation, etc.) with Git
  installed natively, the sandbox still cannot see host binaries — the wrapper
  approach is still required.
