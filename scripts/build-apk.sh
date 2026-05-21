#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════
#  Hill View PWA → Android APK Builder
#  Requires: Node.js, Java 11+, Android SDK
#
#  Usage:
#    ./scripts/build-apk.sh              # full build
#    ./scripts/build-apk.sh --setup-only  # just install deps
#    ./scripts/build-apk.sh --package     # generate APK only
# ═══════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_DIR/docs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prereqs() {
  local missing=0

  if ! command -v node &>/dev/null; then
    error "Node.js is not installed"
    missing=1
  fi

  if ! command -v java &>/dev/null; then
    error "Java is not installed (required for Android tools)"
    missing=1
  fi

  if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ]; then
    warn "ANDROID_HOME/ANDROID_SDK_ROOT not set"
    warn "Install Android SDK: https://developer.android.com/studio#command-line-tools-only"
    missing=1
  fi

  if ! command -v bubblewrap &>/dev/null; then
    warn "Bubblewrap CLI not found. Will install."
  fi

  if [ "$missing" -eq 1 ]; then
    error "Missing prerequisites. Install them first."
    exit 1
  fi
}

# Install Bubblewrap
setup_bubblewrap() {
  if command -v bubblewrap &>/dev/null; then
    info "Bubblewrap already installed"
    return
  fi

  info "Installing Bubblewrap CLI..."
  npm install -g @bubblewrap/cli

  info "Initializing Bubblewrap..."
  bubblewrap init --manifest="$DOCS_DIR/manifest.webmanifest" 2>/dev/null || true
}

# Build the APK
build_apk() {
  local twa_dir="$PROJECT_DIR/android"

  if [ ! -f "$twa_dir/twa-manifest.json" ]; then
    info "Creating TWA project..."
    mkdir -p "$twa_dir"
    cp "$PROJECT_DIR/twa-manifest.json" "$twa_dir/twa-manifest.json"
  fi

  cd "$twa_dir"

  info "Building Android APK..."
  bubblewrap build

  # Find and copy the APK
  local apk_file
  apk_file=$(find "$twa_dir" -name "*.apk" -type f 2>/dev/null | head -1)
  if [ -n "$apk_file" ]; then
    cp "$apk_file" "$PROJECT_DIR/hillview-app.apk"
    info "APK generated: $PROJECT_DIR/hillview-app.apk"
  else
    error "APK not found after build"
    exit 1
  fi
}

# Quick alternative: PWABuilder.com
show_pwabuilder_instructions() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Alternative: Use PWABuilder.com (no SDK required)"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "  1. Deploy the app to GitHub Pages:"
  echo "     npm run build:docs"
  echo "     git add docs/ && git commit -m 'Deploy'"
  echo "     git push"
  echo ""
  echo "  2. Go to https://pwabuilder.com"
  echo "  3. Enter your GitHub Pages URL"
  echo "  4. Click 'Package for Android'"
  echo "  5. Download the generated APK"
  echo ""
}

# Main
main() {
  echo ""
  echo "  ╔════════════════════════════════════════╗"
  echo "  ║  Hill View Android APK Builder         ║"
  echo "  ╚════════════════════════════════════════╝"
  echo ""

  if [ "${1:-}" = "--setup-only" ]; then
    setup_bubblewrap
    info "Setup complete!"
    exit 0
  fi

  if [ "${1:-}" = "--package" ]; then
    build_apk
    exit 0
  fi

  # Full build
  check_prereqs
  setup_bubblewrap

  # Build the web app first
  info "Building web app..."
  npm --prefix "$PROJECT_DIR" run build:docs

  build_apk
  show_pwabuilder_instructions

  info "Done! APK saved to hillview-app.apk"
  echo ""
  info "Alternatively, use PWABuilder.com for a no-hassle build."
}

main "$@"
