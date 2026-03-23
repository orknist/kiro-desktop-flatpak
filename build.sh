#!/usr/bin/env bash
# =============================================================================
# build.sh — Unofficial Flatpak build script for Kiro IDE (desktop variant)
#
# Usage:
#   ./build.sh                  # Build only (creates local repo)
#   ./build.sh --install        # Build and install for the current user
#   ./build.sh --bundle         # Build and produce a .flatpak bundle file
# =============================================================================
set -euo pipefail

APP_ID="kiro.desktop.unofficial"
BUILD_DIR=".flatpak-build"
REPO_DIR=".flatpak-repo"
MANIFEST="${APP_ID}.yml"

# Terminal colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---- Architecture detection ------------------------------------------------
HOST_ARCH=$(uname -m)
case "$HOST_ARCH" in
  x86_64)  KIRO_ARCH="x64" ;;
  aarch64) KIRO_ARCH="arm64" ;;
  *) die "Unsupported architecture: $HOST_ARCH" ;;
esac

METADATA_URL="https://prod.download.desktop.kiro.dev/stable/metadata-linux-${KIRO_ARCH}-stable.json"

# ---- Dependency check -------------------------------------------------------
for cmd in flatpak curl jq sha256sum sed; do
  command -v "$cmd" &>/dev/null || die "'$cmd' not found. Please install it first."
done

# org.flatpak.Builder must be installed as a Flatpak (recommended by Flathub)
flatpak info org.flatpak.Builder &>/dev/null || \
  die "org.flatpak.Builder is not installed. Run: flatpak install flathub org.flatpak.Builder"

# ---- Ensure required Flatpak runtimes are present --------------------------
info "Checking Flathub remote..."
flatpak remote-add --if-not-exists --user flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

for dep in \
  "org.freedesktop.Platform//25.08" \
  "org.freedesktop.Sdk//25.08" \
  "org.electronjs.Electron2.BaseApp//25.08"; do
  if ! flatpak info --user "$dep" &>/dev/null; then
    info "Installing: $dep"
    flatpak install --user --noninteractive flathub "$dep"
  else
    success "Already installed: $dep"
  fi
done

# ---- Fetch latest version from Kiro metadata API ---------------------------
info "Querying Kiro metadata API (arch: ${KIRO_ARCH})..."
METADATA=$(curl -fsSL "$METADATA_URL" 2>/dev/null) \
  || die "Could not fetch metadata for linux-${KIRO_ARCH}. Kiro may not yet provide a binary for this architecture."

KIRO_URL=$(echo "$METADATA" \
  | jq -r '.releases[].updateTo.url' \
  | grep '\.tar\.gz' || true)
KIRO_URL=$(echo "$KIRO_URL" | head -1)
KIRO_VERSION=$(echo "$METADATA" \
  | jq -r '.currentRelease')

[ -z "$KIRO_URL" ]     && die "Could not retrieve download URL from metadata."
[ -z "$KIRO_VERSION" ] && KIRO_VERSION="unknown"

info "Version : $KIRO_VERSION"
info "URL     : $KIRO_URL"

# ---- Cache: skip download if the same version is already present -----------
TARBALL_CACHE=".cache/kiro-${KIRO_VERSION}-${KIRO_ARCH}.tar.gz"
mkdir -p .cache

if [ ! -f "$TARBALL_CACHE" ]; then
  info "Downloading kiro-${KIRO_VERSION}.tar.gz ..."
  curl -L --progress-bar -o "$TARBALL_CACHE" "$KIRO_URL"
else
  success "Cached archive found: $TARBALL_CACHE"
fi

# ---- Compute SHA256 --------------------------------------------------------
info "Computing SHA256..."
KIRO_SHA256=$(sha256sum "$TARBALL_CACHE" | awk '{print $1}')
success "SHA256: $KIRO_SHA256"

# ---- Fill placeholders in a temporary copy of the manifest -----------------
KIRO_DATE=$(date +%Y-%m-%d)
GIT_SHORT_HASH=$(git -C "$(dirname -- "$0")" rev-parse --short HEAD 2>/dev/null || echo "nogit")
KIRO_RELEASE="${KIRO_VERSION}+${GIT_SHORT_HASH}"
info "Release : $KIRO_RELEASE (commit: $GIT_SHORT_HASH)"

MANIFEST_TMP="${MANIFEST%.yml}.generated.yml"
METAINFO_SRC="${APP_ID}.metainfo.xml"
METAINFO_TMP="${APP_ID}.metainfo.generated.xml"

sed \
  -e "s|KIRO_URL_PLACEHOLDER|${KIRO_URL}|g" \
  -e "s|KIRO_SHA256_PLACEHOLDER|${KIRO_SHA256}|g" \
  -e "s|KIRO_VERSION_PLACEHOLDER|${KIRO_RELEASE}|g" \
  -e "s|KIRO_DATE_PLACEHOLDER|${KIRO_DATE}|g" \
  "$MANIFEST" > "$MANIFEST_TMP"

sed \
  -e "s|KIRO_VERSION_PLACEHOLDER|${KIRO_VERSION}|g" \
  -e "s|KIRO_DATE_PLACEHOLDER|${KIRO_DATE}|g" \
  "$METAINFO_SRC" > "$METAINFO_TMP"

# ---- Build -----------------------------------------------------------------
info "Building Flatpak (this may take a few minutes)..."
# org.flatpak.Builder runs in a sandbox — use absolute paths so it can find everything
WORKDIR="$(pwd)"
flatpak run --filesystem=host org.flatpak.Builder \
  --force-clean \
  --disable-rofiles-fuse \
  --state-dir="${WORKDIR}/.flatpak-builder-state" \
  --repo="${WORKDIR}/${REPO_DIR}" \
  "${WORKDIR}/${BUILD_DIR}" \
  "${WORKDIR}/${MANIFEST_TMP}"

success "Build complete!"

# ---- Post-build options ----------------------------------------------------
case "${1:-}" in
  --install)
    info "Installing for current user..."
    flatpak --user remote-add --no-gpg-verify --if-not-exists \
      kiro-local "$REPO_DIR"
    flatpak --user install --noninteractive --reinstall \
      kiro-local "$APP_ID"
    success "Installed. Run with: flatpak run $APP_ID"
    ;;
  --bundle)
    BUNDLE_FILE="${APP_ID}-${KIRO_RELEASE:-${KIRO_VERSION}}.flatpak"
    info "Creating bundle: $BUNDLE_FILE"
    flatpak build-bundle "$REPO_DIR" "$BUNDLE_FILE" "$APP_ID"
    success "Bundle ready: $BUNDLE_FILE"
    info "Users can install it with:"
    echo "  flatpak install --user $BUNDLE_FILE"
    ;;
  --run)
    info "Launching Kiro from build directory (no install)..."
    flatpak run --filesystem=host org.flatpak.Builder \
      --run "${WORKDIR}/${BUILD_DIR}" "${WORKDIR}/${MANIFEST_TMP}" \
      kiro --no-sandbox
    ;;
  "")
    info "Repo ready at: $REPO_DIR"
    info "To install:    ./build.sh --install"
    info "To bundle:     ./build.sh --bundle"
    info "To test run:   ./build.sh --run"
    ;;
  *)
    die "Unknown option: $1  (valid: --install | --bundle | --run)"
    ;;
esac

# Clean up temporary files
rm -f "$MANIFEST_TMP" "$METAINFO_TMP"
