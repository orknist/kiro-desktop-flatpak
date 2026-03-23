#!/usr/bin/env bash
# Wrapper script for running Kiro inside Flatpak.
# Flatpak already provides its own sandbox, so Electron's built-in
# Chromium sandbox is redundant and often causes issues (SUID/user-namespace
# conflicts). --disable-gpu-sandbox avoids GPU process crashes inside
# the container.

# ---------------------------------------------------------------------------
# Ozone platform selection
# ---------------------------------------------------------------------------
#   "auto" relies on XDG_SESSION_TYPE being set correctly, but many
#   environments (VMware guests, TTY logins, some display managers) leave
#   it empty — causing a fatal crash.
#
#   Detection order:
#     1. WSL  → check Wayland socket, fallback to x11
#     2. Explicit ELECTRON_OZONE_PLATFORM_HINT from user → honour it
#     3. XDG_SESSION_TYPE is set → use it directly
#     4. Probe: Wayland socket exists → wayland
#     5. Probe: DISPLAY is set (X11) → x11
#     6. Last resort → x11
# ---------------------------------------------------------------------------

detect_ozone_platform() {
  # 1) WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-0" ] || \
       [ -S "/mnt/wslg/runtime-dir/wayland-0" ]; then
      echo "wayland"; return
    fi
    echo "x11"; return
  fi

  # 2) User override
  if [ -n "${ELECTRON_OZONE_PLATFORM_HINT:-}" ] && \
     [ "${ELECTRON_OZONE_PLATFORM_HINT}" != "auto" ]; then
    echo "${ELECTRON_OZONE_PLATFORM_HINT}"; return
  fi

  # 3) XDG_SESSION_TYPE (set by login manager)
  case "${XDG_SESSION_TYPE:-}" in
    wayland) echo "wayland"; return ;;
    x11)     echo "x11";     return ;;
  esac

  # 4) Probe for Wayland compositor socket
  if [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-0" ]; then
    echo "wayland"; return
  fi

  # 5) Probe for X11
  if [ -n "${DISPLAY:-}" ]; then
    echo "x11"; return
  fi

  # 6) Safe fallback
  echo "x11"
}

OZONE_PLATFORM="$(detect_ozone_platform)"

exec /app/kiro/kiro --no-sandbox --disable-gpu-sandbox --ozone-platform="${OZONE_PLATFORM}" "$@"
