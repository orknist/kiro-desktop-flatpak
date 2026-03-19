#!/usr/bin/env bash
# Wrapper script for running Kiro inside Flatpak.
# Flatpak already provides its own sandbox, so Electron's built-in
# Chromium sandbox is redundant and often causes issues (SUID/user-namespace
# conflicts). --disable-gpu-sandbox avoids GPU process crashes inside
# the container.

# Ozone platform selection:
#   WSLg provides Wayland via /mnt/wslg, but Flatpak may not resolve the
#   symlink from XDG_RUNTIME_DIR. "auto" fails because it can't probe the
#   compositor inside the sandbox. We detect WSL and pick explicitly.
#   On native Linux, "auto" picks Wayland when available, else X11.
if grep -qi microsoft /proc/version 2>/dev/null; then
  if [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-0" ] || \
     [ -S "/mnt/wslg/runtime-dir/wayland-0" ]; then
    OZONE_PLATFORM="wayland"
  else
    OZONE_PLATFORM="x11"
  fi
else
  OZONE_PLATFORM="${ELECTRON_OZONE_PLATFORM_HINT:-auto}"
fi

exec /app/kiro/kiro --no-sandbox --disable-gpu-sandbox --ozone-platform="${OZONE_PLATFORM}" "$@"
