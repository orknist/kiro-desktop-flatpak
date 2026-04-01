# Kiro (Flatpak) + Docker Setup Guide

> Applies to: `kiro.desktop.unofficial` Flatpak on systems with Docker
> Tested on: Ubuntu (mutable), applies to any distro with Docker installed natively

---

## Prerequisites

- Docker installed and the daemon running
- Your user added to the `docker` group

```bash
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect
docker ps  # verify
```

---

## 1. Create the `docker` wrapper

Kiro runs in a Flatpak sandbox and cannot see the host's `/usr/bin/docker`.
We use `flatpak-spawn --host` to bridge the sandbox to the host binary.

```bash
mkdir -p ~/.var/app/kiro.desktop.unofficial/data/bin

cat > ~/.var/app/kiro.desktop.unofficial/data/bin/docker << 'EOF'
#!/bin/bash
exec /usr/bin/flatpak-spawn --host docker "$@"
EOF

chmod +x ~/.var/app/kiro.desktop.unofficial/data/bin/docker
```

Verify it works:

```bash
~/.var/app/kiro.desktop.unofficial/data/bin/docker ps
```

---

## 2. Apply Flatpak overrides

```bash
flatpak override --user \
  --filesystem=/tmp \
  --filesystem=/run/docker.sock \
  --env="PATH=/var/home/$USER/.var/app/kiro.desktop.unofficial/data/bin:/app/bin:/usr/bin" \
  kiro.desktop.unofficial
```

> **Note:** `/tmp` is required because Kiro writes bootstrap files there that
> Docker needs to read. Without it, you'll get:
> `Error: context must be a directory: "/tmp/..."`

> **Note:** On **immutable distros** (Fedora Silverblue, Bazzite, uBlue, etc.)
> Docker is not officially supported. Use Podman instead — see the Podman guide.
> If you still want Docker on an immutable distro, you must install it via
> `rpm-ostree` or inside a Distrobox container, and adjust the socket path
> accordingly.

Verify overrides:

```bash
flatpak override --user --show kiro.desktop.unofficial
```

---

## 3. Configure Kiro settings

In Kiro's `settings.json`:

```json
{
  "dev.containers.dockerPath": "/var/home/YOUR_USERNAME/.var/app/kiro.desktop.unofficial/data/bin/docker",
  "docker.dockerPath": "/var/home/YOUR_USERNAME/.var/app/kiro.desktop.unofficial/data/bin/docker",
  "dev.containers.dockerSocketPath": "/run/docker.sock"
}
```

Replace `YOUR_USERNAME` with your actual username.

---

## Notes

- Flatpak overrides persist across Flatpak updates and are stored at:
  `~/.local/share/flatpak/overrides/kiro.desktop.unofficial`
- The wrapper script in `data/bin/` also persists across updates.
- Docker's default socket is `/run/docker.sock`. If your setup uses a different
  path, adjust the `--filesystem` override and `dockerSocketPath` accordingly.
- On **immutable distros**, prefer Podman — see the separate Podman guide.
