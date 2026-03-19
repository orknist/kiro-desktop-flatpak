#!/usr/bin/env bash
# Wrapper script for running Kiro inside Flatpak.
# Flatpak already provides its own sandbox, so Electron's built-in
# Chromium sandbox is redundant and often causes issues (SUID/user-namespace
# conflicts). --disable-gpu-sandbox avoids GPU process crashes inside
# the container.
exec /app/kiro/kiro --no-sandbox --disable-gpu-sandbox "$@"
