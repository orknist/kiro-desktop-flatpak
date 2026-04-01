# Kiro (Flatpak) + Podman Setup Guide

> Applies to: `kiro.desktop.unofficial` Flatpak on systems with Podman
> Tested on: Fedora Silverblue 43

---

## Prerequisites

- Podman installed and running
- Podman socket enabled

```bash
systemctl --user enable --now podman.socket
systemctl --user status podman.socket
```

---

## 1. Create the `podman` wrapper

Kiro runs in a Flatpak sandbox and cannot see the host's `/usr/bin/podman`.
We use `flatpak-spawn --host` to bridge the sandbox to the host binary.

```bash
mkdir -p ~/.var/app/kiro.desktop.unofficial/data/bin

cat > ~/.var/app/kiro.desktop.unofficial/data/bin/podman << 'EOF'
#!/bin/bash
exec /usr/bin/flatpak-spawn --host podman "$@"
EOF

chmod +x ~/.var/app/kiro.desktop.unofficial/data/bin/podman
```

Verify it works:

```bash
~/.var/app/kiro.desktop.unofficial/data/bin/podman ps
```

---

## 2. Apply Flatpak overrides

```bash
flatpak override --user \
  --filesystem=/tmp \
  --filesystem=/run/user/1000/podman/podman.sock \
  --env="PATH=/var/home/$USER/.var/app/kiro.desktop.unofficial/data/bin:/app/bin:/usr/bin" \
  kiro.desktop.unofficial
```

> **Note:** `/tmp` is required because Kiro writes bootstrap files there that
> Podman needs to read. Without it, you'll get:
> `Error: context must be a directory: "/tmp/..."`

Verify overrides:

```bash
flatpak override --user --show kiro.desktop.unofficial
```

---

## 3. Configure Kiro settings

In Kiro's `settings.json`:

```json
{
  "dev.containers.dockerPath": "/var/home/YOUR_USERNAME/.var/app/kiro.desktop.unofficial/data/bin/podman",
  "docker.dockerPath": "/var/home/YOUR_USERNAME/.var/app/kiro.desktop.unofficial/data/bin/podman",
  "dev.containers.dockerSocketPath": "/run/user/1000/podman/podman.sock"
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
- On **mutable** distros (standard Ubuntu, Fedora Workstation, etc.) with Podman
  installed natively, the sandbox still cannot see host binaries — the wrapper
  approach is still required.
